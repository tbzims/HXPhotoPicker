//
//  TMTMHXActionSheet.swift
//  HXPhotoPicker
//
//  Created by user on 2026/1/8.
//  Copyright © 2026 Silence. All rights reserved.
//

import UIKit

public class TMHXActionSheet: UIView {

    private let masksView = UIView()
    private let container = UIView()
    private let actionBgView = UIView()
    private var cancelStr : String = "Cancel"

    private var actions: [TMHXAction] = []

    public struct TMHXAction {
        let title: String
        let isAutoDismiss: Bool
        let handler: (() -> Void)?

        public init(title: String,
                    isAutoDismiss: Bool = true,
                    handler: (() -> Void)? = nil) {
            self.title = title
            self.isAutoDismiss = isAutoDismiss
            self.handler = handler
        }
    }

    // MARK: - Show

    public static func show(actions: [TMHXAction],cancelStr:String,cancelColor:UIColor) {

        guard let window = UIApplication.shared.keyWindow else { return }

        let sheet = TMHXActionSheet(frame: window.bounds)
        sheet.actions = actions
        window.addSubview(sheet)

        sheet.setupUI(cancelStr,cancelColor)
        sheet.animateShow()
    }

    // MARK: - Dismiss

    public static func dismiss() {
        guard let window = UIApplication.shared.keyWindow else { return }
        for view in window.subviews {
            if let sheet = view as? TMHXActionSheet {
                sheet.animateDismiss()
                break
            }
        }
    }

    // MARK: - UI Setup

    private func setupUI(_ cancelStr:String,_ cancelColor:UIColor) {

        masksView.frame = bounds
        masksView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        addSubview(masksView)

        masksView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(maskTapped)))

        container.backgroundColor = .clear
        addSubview(container)
        
        actionBgView.backgroundColor = .white
        actionBgView.layer.cornerRadius = 12
        actionBgView.layer.masksToBounds = true
        container.addSubview(actionBgView)

        var y: CGFloat = 0

        // Actions
        for (i, action) in actions.enumerated() {
            let btn = UIButton(type: .custom)
            btn.setTitle(action.title, for: .normal)
            btn.setTitleColor(UIColor(hexString: "#121212"), for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 17,weight: .regular)
            btn.frame = CGRect(x: 0, y: y, width: bounds.width - 26, height: 55)
            btn.tag = i
            btn.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
            btn.backgroundColor = .white
            actionBgView.addSubview(btn)
            y += 55

            if i < actions.count - 1 {
                addSeparator(y: &y)
            }
        }

        actionBgView.frame = CGRect(x: 0, y: 0, width: bounds.width - 26, height: y)
        container.frame = CGRect(x: 20, y: bounds.height, width: bounds.width - 26, height: actionBgView.frame.size.height + 62)
        
        let btn = UIButton(type: .custom)
        btn.setTitle(cancelStr, for: .normal)
        btn.setTitleColor(cancelColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17,weight: .medium)
        btn.frame = CGRect(x: 0, y: CGRectGetMaxY(actionBgView.frame) + 8, width: bounds.width - 26, height: 54)
        btn.tag = -1
        btn.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
        btn.backgroundColor = .white
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 12
        container.addSubview(btn)

    }

    private func addSeparator(y: inout CGFloat) {
        let line = UIView(frame: CGRect(x: 0, y: y, width: bounds.width - 26, height: 0.5))
        line.backgroundColor = UIColor(white: 0.85, alpha: 1)
        actionBgView.addSubview(line)
        y += 0.5
    }

    // MARK: - Animations

    private func animateShow() {
        UIView.animate(withDuration: 0.25) {
            self.masksView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            self.container.transform = CGAffineTransform(translationX: 0, y: -(self.container.bounds.height + 20))
        }
    }

    private func animateDismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.masksView.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.container.transform = .identity
        }) { _ in
            self.removeFromSuperview()
        }
    }

    @objc private func maskTapped() {
        Self.dismiss()
    }

    @objc private func actionTapped(_ sender: UIButton) {
        if sender.tag == -1 {
            Self.dismiss()
            return
        }
        let action = actions[sender.tag]
        if action.isAutoDismiss {
            Self.dismiss()
        }
        action.handler?()
    }
}
