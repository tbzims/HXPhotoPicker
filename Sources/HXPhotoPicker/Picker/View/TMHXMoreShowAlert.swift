//
//  TMHXMoreShowAlert.swift
//  HXPhotoPicker
//
//  Created by user on 2026/3/19.
//  Copyright © 2026 Silence. All rights reserved.
//

import UIKit

final class TMHXMoreShowAlert: UIView {
    
    var onClickItem: ((TMHXMoreItemModel, [TMHXMoreItemModel]) -> Void)?
    var onDismiss: (([TMHXMoreItemModel]) -> Void)?
    
    private var items: [TMHXMoreItemModel]
    private let rowHeight: CGFloat = 42
    private let contentWidth: CGFloat = 268
    private let contentCornerRadius: CGFloat = 20
    private let contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    private let menuHorizontalPadding: CGFloat = 0
    private let menuVerticalPadding: CGFloat = 0
    private let overlayAlpha: CGFloat = 0.5
    
    private let alertMaskView = UIView()
    private let shadowView = UIView()
    private let contentView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let tableView = UITableView()
    
    private weak var anchorView: UIView?
    private var topConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    
    init(items: [TMHXMoreItemModel]) {
        self.items = items
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TMHXMoreShowAlert {
    
    var safeBottom: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }
    
    var contentHeight: CGFloat {
        CGFloat(items.count) * rowHeight + contentInset.top + contentInset.bottom
    }
    
    func setupUI() {
        backgroundColor = .clear
        
        alertMaskView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(alertMaskView)
        addSubview(shadowView)
        shadowView.addSubview(contentView)
        contentView.contentView.addSubview(tableView)
        
        // mask
        alertMaskView.backgroundColor = UIColor.black.withAlphaComponent(overlayAlpha)
        alertMaskView.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        alertMaskView.addGestureRecognizer(tap)
        
        // shadow container
        shadowView.alpha = 0
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.18
        shadowView.layer.shadowRadius = 12
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 8)
        shadowView.backgroundColor = .clear
        
        // blur content
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = contentCornerRadius
        if #available(iOS 13.0, *) {
            contentView.layer.cornerCurve = .continuous
        }
        
        // table
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = rowHeight
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TMHXMoreShowAlertCell.self, forCellReuseIdentifier: TMHXMoreShowAlertCell.reuseId)
        
        NSLayoutConstraint.activate([
            alertMaskView.topAnchor.constraint(equalTo: topAnchor),
            alertMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),
            alertMaskView.leadingAnchor.constraint(equalTo: leadingAnchor),
            alertMaskView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            shadowView.widthAnchor.constraint(equalToConstant: contentWidth),
            shadowView.heightAnchor.constraint(equalToConstant: contentHeight),
            
            contentView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: contentView.contentView.topAnchor, constant: contentInset.top),
            tableView.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor, constant: -contentInset.bottom),
            tableView.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
        ])
        
        leadingConstraint = shadowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: menuHorizontalPadding)
        topConstraint = shadowView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        NSLayoutConstraint.activate([leadingConstraint, topConstraint])
    }
}

extension TMHXMoreShowAlert {
    
    func show(from anchorView: UIView, in view: UIView? = nil) {
        self.anchorView = anchorView
        let containerView = view ?? anchorView.window ?? UIApplication.shared.windows.first
        guard let containerView else {
            return
        }
        
        frame = containerView.bounds
        containerView.addSubview(self)
        repositionContentView()
        layoutIfNeeded()
        
        shadowView.transform = CGAffineTransform(translationX: 0, y: -12).scaledBy(x: 0.96, y: 0.96)
        
        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            usingSpringWithDamping: 0.92,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut]
        ) {
            self.alertMaskView.alpha = 1
            self.shadowView.alpha = 1
            self.shadowView.transform = .identity
            self.layoutIfNeeded()
        }
    }
    
    @objc
    func dismissSelf() {
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn]) {
            self.alertMaskView.alpha = 0
            self.shadowView.alpha = 0
            self.shadowView.transform = CGAffineTransform(translationX: 0, y: -8).scaledBy(x: 0.98, y: 0.98)
        } completion: { _ in
            let result = self.items
            self.removeFromSuperview()
            self.onDismiss?(result)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        repositionContentView()
    }
    
    private func repositionContentView() {
        guard let anchorView else {
            return
        }
        let anchorFrame = anchorView.convert(anchorView.bounds, to: self)
        let maxX = bounds.width - menuHorizontalPadding - contentWidth
        let preferredX = anchorFrame.maxX - contentWidth
        leadingConstraint.constant = max(menuHorizontalPadding, min(preferredX, maxX))
        
        let preferredY = max(anchorFrame.maxY + menuVerticalPadding, minimumTopPosition())
        let maxY = bounds.height - safeBottom - menuVerticalPadding - contentHeight
        topConstraint.constant = max(minimumTopPosition(), min(preferredY, maxY))
    }
    
    private func minimumTopPosition() -> CGFloat {
        let fallbackTop = safeAreaInsets.top + menuVerticalPadding
        guard let anchorView,
              let viewController = anchorView.findViewController()
        else {
            return fallbackTop
        }
        
        if let navigationBar = viewController.navigationController?.navigationBar {
            let navigationFrame = navigationBar.convert(navigationBar.bounds, to: self)
            return max(fallbackTop, navigationFrame.maxY + menuVerticalPadding)
        }
        return fallbackTop
    }
}

extension TMHXMoreShowAlert: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TMHXMoreShowAlertCell.reuseId,
            for: indexPath
        ) as? TMHXMoreShowAlertCell else {
            return UITableViewCell()
        }
        
        cell.update(model: items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].isSelected.toggle()
        tableView.reloadRows(at: [indexPath], with: .none)
        onClickItem?(items[indexPath.row], items)
    }
}

final class TMHXMoreShowAlertCell: UITableViewCell {
    
    static let reuseId = "TMHXMoreShowAlertCell"
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let checkImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TMHXMoreShowAlertCell {
    
    func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        checkImageView.image = UIImage(systemName: "checkmark")
        checkImageView.tintColor = .white
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            checkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkImageView.widthAnchor.constraint(equalToConstant: 18),
            checkImageView.heightAnchor.constraint(equalToConstant: 18),
        ])
    }
}

extension TMHXMoreShowAlertCell {
    
    func update(model: TMHXMoreItemModel) {
        iconImageView.image = model.icon?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = model.title
        checkImageView.isHidden = !model.isSelected
    }
}

final class TMHXMoreItemModel {
    
    let id: String
    let title: String
    let icon: UIImage?
    var isSelected: Bool
    
    init(
        id: String,
        title: String,
        icon: UIImage? = nil,
        isSelected: Bool = false
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
    }
}

private extension UIView {
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}
