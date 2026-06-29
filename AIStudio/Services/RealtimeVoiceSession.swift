import Foundation
import AVFoundation

// MARK: - RealtimeVoiceSession
// Connects to the OpenAI Realtime API over WebSocket using the ephemeral client_secret
// minted by our Dola backend, streams microphone audio (PCM16 24kHz mono), plays back
// the model's audio, and accumulates the conversation transcript.
//
// Threading: all mutable session state (isStopped, turns), audio-graph mutation
// (engine teardown, playerNode scheduling) and WebSocket send/cancel are serialized on
// `queue`. Audio render-thread callbacks and the URLSession delegate queue hop onto it
// before touching shared state, so teardown never races the receive/playback paths.
//
// Runtime note: requires a real ephemeral key + reachable api.openai.com + a microphone.
// In the sandbox the key is a stub, so connection fails and onError fires gracefully.
final class RealtimeVoiceSession: NSObject {
    enum State { case connecting, listening, speaking, ended, failed }

    var onStateChange: ((State) -> Void)?
    var onUserTranscript: ((String) -> Void)?
    var onAssistantTranscript: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private let credentials: DolaRealtimeSession
    private let instructions: String?
    private let queue = DispatchQueue(label: "com.aistudio.realtime.voice")

    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 24000
    private lazy var streamFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private var converter: AVAudioConverter?

    private var isStopped = false   // touched only on `queue`
    private var isMuted = false
    private var startedAt = Date()
    private var turns: [DolaRealtimeTurn] = []   // touched only on `queue`
    private var pendingAssistant = ""            // touched only on `queue`

    init(credentials: DolaRealtimeSession, instructions: String?) {
        self.credentials = credentials
        self.instructions = instructions
    }

    // MARK: - Lifecycle

    func start() {
        startedAt = Date()
        setState(.connecting)
        connect()
        startAudio()
    }

    func setMuted(_ muted: Bool) { isMuted = muted }

    func stop() -> (turns: [DolaRealtimeTurn], duration: Int) {
        queue.sync {
            guard !isStopped else { return }
            isStopped = true
            flushAssistantLocked()
            webSocket?.cancel(with: .goingAway, reason: nil)
            teardownAudioLocked()
        }
        setState(.ended)
        return (turns, max(1, Int(Date().timeIntervalSince(startedAt))))
    }

    // MARK: - WebSocket

    private func connect() {
        guard var components = URLComponents(string: "wss://api.openai.com/v1/realtime") else { return }
        components.queryItems = [URLQueryItem(name: "model", value: credentials.model)]
        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.clientSecret)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        let session = URLSession(configuration: .default)
        urlSession = session
        let task = session.webSocketTask(with: request)
        webSocket = task
        task.resume()
        configureSession()
        scheduleReceive()
    }

    private func configureSession() {
        var sessionConfig: [String: Any] = [
            "modalities": ["audio", "text"],
            "voice": credentials.voice,
            "input_audio_format": "pcm16",
            "output_audio_format": "pcm16",
            "turn_detection": ["type": "server_vad"],
            "input_audio_transcription": ["model": "whisper-1"]
        ]
        if let instructions, !instructions.isEmpty { sessionConfig["instructions"] = instructions }
        send(["type": "session.update", "session": sessionConfig])
    }

    private func scheduleReceive() {
        webSocket?.receive { [weak self] result in
            guard let self else { return }
            self.queue.async {
                guard !self.isStopped else { return }
                switch result {
                case .success(let message):
                    if case .string(let text) = message { self.handleEventLocked(text) }
                    self.scheduleReceive()
                case .failure(let error):
                    self.failLocked(error.localizedDescription)
                }
            }
        }
    }

    private func send(_ object: [String: Any]) {
        queue.async { [weak self] in
            guard let self, !self.isStopped, let socket = self.webSocket,
                  let data = try? JSONSerialization.data(withJSONObject: object),
                  let string = String(data: data, encoding: .utf8) else { return }
            socket.send(.string(string)) { _ in }
        }
    }

    // MARK: - Incoming events (on `queue`)

    private func handleEventLocked(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "response.audio.delta":
            if let b64 = json["delta"] as? String, let audio = Data(base64Encoded: b64) {
                enqueueAudioLocked(audio)
                setState(.speaking)
            }
        case "response.audio.done", "response.done":
            setState(.listening)
        case "response.audio_transcript.delta":
            if let delta = json["delta"] as? String { pendingAssistant += delta }
        case "response.audio_transcript.done":
            flushAssistantLocked()
        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String, !transcript.isEmpty {
                turns.append(DolaRealtimeTurn(role: "user", content: transcript))
                dispatch { self.onUserTranscript?(transcript) }
            }
        case "error":
            let message = (json["error"] as? [String: Any])?["message"] as? String
            failLocked(message ?? "Realtime error")
        default:
            break
        }
    }

    private func flushAssistantLocked() {
        let text = pendingAssistant.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingAssistant = ""
        guard !text.isEmpty else { return }
        turns.append(DolaRealtimeTurn(role: "assistant", content: text))
        dispatch { self.onAssistantTranscript?(text) }
    }

    // MARK: - Audio

    private func startAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: streamFormat)

            let input = engine.inputNode
            let hardwareFormat = input.inputFormat(forBus: 0)
            let captureFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: sampleRate, channels: 1, interleaved: true)!
            converter = AVAudioConverter(from: hardwareFormat, to: captureFormat)

            input.installTap(onBus: 0, bufferSize: 2048, format: hardwareFormat) { [weak self] buffer, _ in
                self?.handleMicBuffer(buffer, to: captureFormat)
            }

            engine.prepare()
            try engine.start()
            playerNode.play()
            setState(.listening)
        } catch {
            fail(error.localizedDescription)
        }
    }

    // Runs on the audio render thread: convert here (the converter is created once and
    // never torn down), then hand the encoded bytes to `queue` for the guarded send.
    private func handleMicBuffer(_ buffer: AVAudioPCMBuffer, to captureFormat: AVAudioFormat) {
        guard !isMuted, let converter else { return }
        let ratio = captureFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 1)
        guard let out = AVAudioPCMBuffer(pcmFormat: captureFormat, frameCapacity: capacity) else { return }
        var consumed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if consumed { status.pointee = .noDataNow; return nil }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        guard error == nil, let channel = out.int16ChannelData, out.frameLength > 0 else { return }
        let byteCount = Int(out.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: channel[0], count: byteCount)
        send(["type": "input_audio_buffer.append", "audio": data.base64EncodedString()])
    }

    private func enqueueAudioLocked(_ pcm16: Data) {
        guard engine.isRunning else { return }
        let frameCount = pcm16.count / MemoryLayout<Int16>.size
        guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: streamFormat, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        pcm16.withUnsafeBytes { raw in
            guard let samples = raw.bindMemory(to: Int16.self).baseAddress,
                  let out = buffer.floatChannelData?[0] else { return }
            for i in 0..<frameCount { out[i] = Float(samples[i]) / 32768.0 }
        }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying { playerNode.play() }
    }

    private func teardownAudioLocked() {
        engine.inputNode.removeTap(onBus: 0)
        playerNode.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Helpers

    private func fail(_ message: String) {
        queue.async { [weak self] in self?.failLocked(message) }
    }

    private func failLocked(_ message: String) {
        guard !isStopped else { return }
        isStopped = true
        webSocket?.cancel(with: .goingAway, reason: nil)
        teardownAudioLocked()
        setState(.failed)
        dispatch { self.onError?(message) }
    }

    private func setState(_ state: State) { dispatch { self.onStateChange?(state) } }

    private func dispatch(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}
