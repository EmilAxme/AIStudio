import Foundation

// MARK: - ChatHistoryStore
final class ChatHistoryStore {
    private let key = "app.chat.sessions"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func sessions() -> [ChatSession] {
        guard let data = defaults.data(forKey: key),
              let stored = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            return []
        }
        return stored.sorted { $0.updatedAt > $1.updatedAt }
    }

    func session(id: UUID) -> ChatSession? {
        sessions().first { $0.id == id }
    }

    func save(_ session: ChatSession) {
        var all = sessions()
        if let index = all.firstIndex(where: { $0.id == session.id }) {
            all[index] = session
        } else {
            all.append(session)
        }
        guard let data = try? JSONEncoder().encode(all) else { return }
        defaults.set(data, forKey: key)
    }
}
