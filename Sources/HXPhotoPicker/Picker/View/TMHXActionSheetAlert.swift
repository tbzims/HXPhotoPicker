//
//  TMHXActionSheetAlert.swift
//  HXPhotoPicker
//
//  Created by user on 2026/1/8.
//  Copyright © 2026 Silence. All rights reserved.
//

import UIKit

public final class TMHXAlertAction {
    public let title: String
    public let font: UIFont
    public let color: UIColor
    public let isAutoDismiss: Bool
    public let handler: (() -> Void)?

    public init(title: String,
                font: UIFont,
                color: UIColor,
                isAutoDismiss: Bool = true,
                handler: (() -> Void)? = nil) {
        self.title = title
        self.font = font
        self.color = color
        self.isAutoDismiss = isAutoDismiss
        self.handler = handler
    }
}

public final class TMHXActionSheetAlert: UIViewController {

    private var actions: [TMHXAlertAction] = []
    private var titleText: String?

    private let dimView = UIView()
    private let containerView = UIView()
    private let actionsContainer = UIView()
    private let cancelButton = UIButton(type: .system)

    private let buttonHeight: CGFloat = 56
    private let cornerRadius: CGFloat = 14
    private let spacing: CGFloat = 8

    // MARK: - Public

    public static func show(title: String? = nil, actions: [TMHXAlertAction]) {
        guard !actions.isEmpty else { return }

        let alert = TMHXActionSheetAlert()
        alert.titleText = title
        alert.actions = actions
        alert.modalPresentationStyle = .overFullScreen
        alert.modalTransitionStyle = .crossDissolve
        
        if let topVC = UIApplication.shared.keyWindowTopController() {
            topVC.present(alert, animated: false, completion: nil)
        }
    }

    // MARK: - LifeCycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        animateIn()
    }

    // MARK: - UI

    private func buildUI() {

        view.backgroundColor = .clear

        // dim layer
        dimView.frame = view.bounds
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.addSubview(dimView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dimView.addGestureRecognizer(tap)

        // container (bottom area)
        containerView.backgroundColor = .clear
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // actions group container
        actionsContainer.backgroundColor = .white
        actionsContainer.layer.cornerRadius = cornerRadius
        actionsContainer.clipsToBounds = true
        containerView.addSubview(actionsContainer)

        actionsContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            actionsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            actionsContainer.topAnchor.constraint(equalTo: containerView.topAnchor)
        ])

        var currentY: CGFloat = 0

        // Title
        if let title = titleText, !title.isEmpty {
            let lbl = UILabel()
            lbl.text = title
            lbl.numberOfLines = 0
            lbl.textAlignment = .center
            lbl.font = UIFont.systemFont(ofSize: 13)
            lbl.textColor = UIColor.darkGray
            lbl.frame = CGRect(x: 16, y: 16, width: view.bounds.width - 40, height: 0)
            lbl.sizeToFit()
            lbl.frame.origin.y = 16
            lbl.frame.origin.x = 16
            lbl.frame.size.width = actionsContainer.bounds.width - 32
            actionsContainer.addSubview(lbl)

            currentY = lbl.frame.maxY + 16
            addSeparator(to: actionsContainer, y: &currentY)
        }

        // Actions
        for (i, action) in actions.enumerated() {
            let btn = createActionButton(action)
            btn.frame = CGRect(x: 0, y: currentY, width: view.bounds.width, height: buttonHeight)
            actionsContainer.addSubview(btn)
            currentY += buttonHeight

            if i < actions.count - 1 {
                addSeparator(to: actionsContainer, y: &currentY)
            }
        }

        // fix actions container height
        let heightConstraint = actionsContainer.heightAnchor.constraint(equalToConstant: currentY)
        heightConstraint.isActive = true

        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        cancelButton.layer.cornerRadius = cornerRadius
        cancelButton.backgroundColor = .white
        cancelButton.clipsToBounds = true
        cancelButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        containerView.addSubview(cancelButton)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: actionsContainer.bottomAnchor, constant: spacing),
            cancelButton.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -spacing)
        ])
    }

    private func addSeparator(to parent: UIView, y: inout CGFloat) {
        let line = UIView(frame: CGRect(x: 0, y: y, width: view.bounds.width, height: 0.5))
        line.backgroundColor = UIColor(white: 0.85, alpha: 1)
        parent.addSubview(line)
        y += 0.5
    }

    private func createActionButton(_ action: TMHXAlertAction) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(action.title, for: .normal)
        btn.setTitleColor(action.color, for: .normal)
        btn.titleLabel?.font = action.font
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        btn.tag = actions.firstIndex(where: { $0 === action })!
        return btn
    }

    @objc private func buttonPressed(_ sender: UIButton) {
        let action = actions[sender.tag]
        if action.isAutoDismiss {
            dismiss(animated: false) { action.handler?() }
        } else {
            action.handler?()
        }
    }

    // MARK: - Animations

    private func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.25) {
            self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            self.containerView.transform = .identity
        }
    }

    @objc private func dismissSelf() {
        UIView.animate(withDuration: 0.25, animations: {
            self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

private extension UIApplication {
    func keyWindowTopController(base: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return keyWindowTopController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return keyWindowTopController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return keyWindowTopController(base: presented) }
        return base
    }
}
