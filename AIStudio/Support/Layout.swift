import UIKit

enum Layout {
    static let horizontalInset: CGFloat = 16
    static let cardRadius: CGFloat = 20
    static let rowRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 28
    static let fieldRadius: CGFloat = 25
    static let pillRadius: CGFloat = 28
}

extension UIView {
    func addSubviews(_ subviews: UIView...) {
        subviews.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }

    func pinToEdges(of view: UIView) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
