import UIKit
import AVFoundation

// MARK: - LoopingVideoView
/// Hosts an AVPlayerLayer that plays a bundled clip on a seamless loop (muted).
/// Playback is driven externally so only on-screen cells keep a player alive.
final class LoopingVideoView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private(set) var sourceKey: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { nil }

    func load(bundledName: String?) {
        guard let bundledName,
              let url = Bundle.main.url(forResource: bundledName, withExtension: "mp4") else { teardown(); return }
        load(url: url, key: "bundle:" + bundledName)
    }

    func load(remoteURL: URL?) {
        guard let remoteURL else { teardown(); return }
        load(url: remoteURL, key: remoteURL.absoluteString)
    }

    private func load(url: URL, key: String) {
        guard key != sourceKey else { return }
        teardown()
        sourceKey = key
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = true
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        playerLayer.player = queue
    }

    func play() { player?.play() }
    func pause() { player?.pause() }

    func teardown() {
        player?.pause()
        playerLayer.player = nil
        looper = nil
        player = nil
        sourceKey = nil
    }
}

// MARK: - VideoTemplateCell
final class VideoTemplateCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoTemplateCell"

    private let posterView = UIImageView()
    private let videoView = LoopingVideoView()
    private let scrim = GradientView(
        colors: [UIColor(hex: 0x1F191F, alpha: 0), UIColor(hex: 0x1F191F, alpha: 0.6)],
        startPoint: CGPoint(x: 0.5, y: 0.4),
        endPoint: CGPoint(x: 0.5, y: 1)
    )
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 24
        contentView.clipsToBounds = true
        contentView.backgroundColor = AppColor.surface
        posterView.contentMode = .scaleAspectFill
        posterView.translatesAutoresizingMaskIntoConstraints = false
        videoView.translatesAutoresizingMaskIntoConstraints = false
        scrim.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = AppFont.regular(16)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterView)
        contentView.addSubview(videoView)
        contentView.addSubview(scrim)
        contentView.addSubview(titleLabel)
        posterView.pinToEdges(of: contentView)
        videoView.pinToEdges(of: contentView)
        NSLayoutConstraint.activate([
            scrim.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrim.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(template: VideoTemplate) {
        titleLabel.text = template.title
        if let url = template.previewURL {
            posterView.image = nil
            videoView.load(remoteURL: url)
        } else {
            posterView.image = template.posterName.flatMap { UIImage(named: $0) }
            videoView.load(bundledName: template.previewVideoName)
        }
    }

    func play() { videoView.play() }
    func pause() { videoView.pause() }

    override func prepareForReuse() {
        super.prepareForReuse()
        videoView.teardown()
        posterView.image = nil
    }
}

// MARK: - CarouselImageCell
final class CarouselImageCell: UICollectionViewCell {
    static let reuseIdentifier = "CarouselImageCell"
    private let imageView = UIImageView()
    private let videoView = LoopingVideoView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        contentView.backgroundColor = AppColor.surface
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        videoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        contentView.addSubview(videoView)
        imageView.pinToEdges(of: contentView)
        videoView.pinToEdges(of: contentView)
    }

    required init?(coder: NSCoder) { nil }

    func configure(image: UIImage?) {
        imageView.image = image
        videoView.teardown()
    }

    func configure(template: VideoTemplate) {
        if let url = template.previewURL {
            imageView.image = nil
            videoView.load(remoteURL: url)
        } else {
            imageView.image = template.posterName.flatMap { UIImage(named: $0) }
            videoView.load(bundledName: template.previewVideoName)
        }
    }

    func play() { videoView.play() }
    func pause() { videoView.pause() }

    override func prepareForReuse() {
        super.prepareForReuse()
        videoView.teardown()
        imageView.image = nil
    }
}

// MARK: - FormOptionView
final class FormOptionView: UIControl {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))

    init(title: String, value: String) {
        super.init(frame: .zero)
        backgroundColor = AppColor.surface
        layer.cornerRadius = 24
        titleLabel.text = title
        titleLabel.textColor = AppColor.secondaryText
        titleLabel.font = AppFont.font(16, .regular)
        valueLabel.text = value
        valueLabel.textColor = .white
        valueLabel.font = AppFont.font(16, .semibold)
        chevron.tintColor = AppColor.secondaryText
        chevron.contentMode = .scaleAspectFit
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        addSubviews(titleLabel, valueLabel, chevron)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    var value: String { valueLabel.text ?? "" }

    func setValue(_ v: String) { valueLabel.text = v }

    func setExpanded(_ expanded: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.chevron.transform = expanded ? CGAffineTransform(rotationAngle: .pi) : .identity
        }
    }
}

// MARK: - UploadTile
final class UploadTile: UIControl {
    private let gradient = GradientView(colors: AppColor.inputGradient)
    private let inner = UIView()
    private let icon = UIImageView(image: UIImage(systemName: "plus"))
    private let photoView = UIImageView()
    private let removeButton = UIButton(type: .system)
    var onRemove: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        layer.cornerRadius = 16

        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.layer.cornerRadius = 16
        gradient.clipsToBounds = true
        inner.backgroundColor = AppColor.background
        inner.layer.cornerRadius = 14.5
        inner.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .light)
        icon.translatesAutoresizingMaskIntoConstraints = false

        photoView.contentMode = .scaleAspectFill
        photoView.layer.cornerRadius = 16
        photoView.clipsToBounds = true
        photoView.isHidden = true
        photoView.translatesAutoresizingMaskIntoConstraints = false

        removeButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)), for: .normal)
        removeButton.tintColor = .white
        removeButton.backgroundColor = UIColor(hex: 0x2A232C)
        removeButton.layer.cornerRadius = 11
        removeButton.layer.borderWidth = 2
        removeButton.layer.borderColor = AppColor.background.cgColor
        removeButton.isHidden = true
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

        addSubviews(gradient, inner, icon, photoView, removeButton)
        gradient.pinToEdges(of: self)
        NSLayoutConstraint.activate([
            inner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1.5),
            inner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1.5),
            inner.topAnchor.constraint(equalTo: topAnchor, constant: 1.5),
            inner.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.5),
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            photoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            photoView.topAnchor.constraint(equalTo: topAnchor),
            photoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            removeButton.centerXAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            removeButton.centerYAnchor.constraint(equalTo: topAnchor, constant: 2),
            removeButton.widthAnchor.constraint(equalToConstant: 22),
            removeButton.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func setImage(_ image: UIImage?) {
        if let image {
            photoView.image = image
            photoView.isHidden = false
            removeButton.isHidden = false
            icon.isHidden = true
            gradient.isHidden = true
            inner.isHidden = true
        } else {
            photoView.image = nil
            photoView.isHidden = true
            removeButton.isHidden = true
            icon.isHidden = false
            gradient.isHidden = false
            inner.isHidden = false
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !removeButton.isHidden {
            let local = convert(point, to: removeButton)
            if removeButton.bounds.insetBy(dx: -10, dy: -10).contains(local) { return removeButton }
        }
        return bounds.contains(point) ? self : nil
    }

    @objc private func removeTapped() { onRemove?() }

}

// MARK: - RatioIconView
final class RatioIconView: UIView {
    init(ratio: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let box = UIView()
        box.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
        box.layer.borderWidth = 1.5
        box.layer.cornerRadius = 3
        box.translatesAutoresizingMaskIntoConstraints = false
        addSubview(box)
        let (w, h): (CGFloat, CGFloat)
        switch ratio {
        case "9:16": (w, h) = (12, 20)
        case "1:1": (w, h) = (17, 17)
        default: (w, h) = (20, 12)
        }
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 22),
            heightAnchor.constraint(equalToConstant: 22),
            box.centerXAnchor.constraint(equalTo: centerXAnchor),
            box.centerYAnchor.constraint(equalTo: centerYAnchor),
            box.widthAnchor.constraint(equalToConstant: w),
            box.heightAnchor.constraint(equalToConstant: h)
        ])
    }
    required init?(coder: NSCoder) { nil }
}

// MARK: - DropdownOverlay
final class DropdownOverlay: UIView {
    private let onSelect: (String) -> Void
    private let onDismiss: () -> Void
    private let panel = UIView()

    init(anchorFrame: CGRect,
         hostBounds: CGRect,
         options: [String],
         selected: String,
         showRatioIcon: Bool,
         onSelect: @escaping (String) -> Void,
         onDismiss: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onDismiss = onDismiss
        super.init(frame: hostBounds)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissTap)))

        panel.backgroundColor = AppColor.surfaceRaised
        panel.layer.cornerRadius = 16
        panel.layer.borderWidth = 1
        panel.layer.borderColor = AppColor.hairline.cgColor
        panel.clipsToBounds = true
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)

        for (index, option) in options.enumerated() {
            stack.addArrangedSubview(makeRow(option: option, isSelected: option == selected, showRatioIcon: showRatioIcon))
            if index < options.count - 1 {
                let sep = UIView()
                sep.backgroundColor = AppColor.hairline
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(sep)
            }
        }

        NSLayoutConstraint.activate([
            panel.widthAnchor.constraint(equalToConstant: 196),
            panel.trailingAnchor.constraint(equalTo: leadingAnchor, constant: anchorFrame.maxX),
            panel.topAnchor.constraint(equalTo: topAnchor, constant: anchorFrame.maxY + 8),
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])

        panel.alpha = 0
        panel.transform = CGAffineTransform(translationX: 0, y: -8).scaledBy(x: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5) {
            self.panel.alpha = 1
            self.panel.transform = .identity
        }
    }

    required init?(coder: NSCoder) { nil }

    private func makeRow(option: String, isSelected: Bool, showRatioIcon: Bool) -> UIControl {
        let row = UIControl()
        let label = UILabel()
        label.text = option
        label.font = AppFont.font(16, isSelected ? .semibold : .medium)
        label.textColor = isSelected ? AppColor.pink : .white
        label.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 46),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        if showRatioIcon {
            let ratioIcon = RatioIconView(ratio: option)
            ratioIcon.alpha = isSelected ? 1 : 0.6
            row.addSubview(ratioIcon)
            NSLayoutConstraint.activate([
                ratioIcon.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
                ratioIcon.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
        }
        row.addAction(UIAction { [weak self] _ in
            self?.onSelect(option)
            self?.removeFromSuperview()
        }, for: .touchUpInside)
        return row
    }

    @objc private func dismissTap() {
        onDismiss()
        removeFromSuperview()
    }
}
