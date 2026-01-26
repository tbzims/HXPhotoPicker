//
//  TMPreviewSelectedGradientMaskView.swift
//  HXPhotoPicker
//
//  Created by user on 2026/1/7.
//  Copyright © 2026 Silence. All rights reserved.
//

import UIKit

class TMPreviewSelectedGradientMaskView: UIView {
    
    private var maskColor : UIColor = .black {
        didSet {
            updateGradientLayer()
        }
    }
    // 渐变层（核心）
    private let gradientLayer = CAGradientLayer()
    
    // 蒙层基准颜色（黑色，可外部调整）
    var maskBaseColor: UIColor = .black {
        didSet {
            updateGradientLayer()
        }
    }
    
    // MARK: - 初始化
    init(frame: CGRect,maskColor:UIColor) {
        self.maskColor = maskColor
        super.init(frame: frame)
        setupView()
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        self.maskColor = .black
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - 布局
    override func layoutSubviews() {
        super.layoutSubviews()
        // 渐变层尺寸跟随View
        gradientLayer.frame = bounds
    }
    
    // MARK: - 私有方法
    private func setupView() {
        // 基础配置：背景透明，避免遮挡
        backgroundColor = .clear
        
        // 配置渐变层
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)  // 渐变起始点（左侧中间）
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)    // 渐变结束点（右侧中间）
        updateGradientLayer()
        
        // 添加渐变层到View层级
        layer.addSublayer(gradientLayer)
    }
    
    /// 更新渐变层颜色配置（alpha 0→1）
    private func updateGradientLayer() {
        // 渐变颜色数组：左侧alpha 0 → 右侧alpha 1
        gradientLayer.colors = [
            maskColor.withAlphaComponent(0).cgColor,
            maskColor.withAlphaComponent(1).cgColor
        ]
        // 渐变位置（0→1 对应View的左→右）
        gradientLayer.locations = [0.0, 1.0]
    }
    
    // MARK: - 便捷创建方法（适配HXPhotoPicker）
    /// 创建蒙层View并添加到指定父视图
    /// - Parameters:
    ///   - superView: 父视图（比如HXPhotoPicker的预览页/相册列表页）
    ///   - frame: 蒙层尺寸（默认铺满父视图）
//    static func addTo(superView: UIView, frame: CGRect? = nil) -> TMPreviewSelectedGradientMaskView {
//        let maskView = TMPreviewSelectedGradientMaskView(frame: frame ?? superView.bounds, maskColor: <#UIColor#>)
//        // 蒙层添加到父视图最上层（可根据需求调整层级）
//        superView.addSubview(maskView)
//        // 自动布局（适配父视图尺寸变化）
//        maskView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            maskView.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
//            maskView.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
//            maskView.topAnchor.constraint(equalTo: superView.topAnchor),
//            maskView.bottomAnchor.constraint(equalTo: superView.bottomAnchor)
//        ])
//        return maskView
//    }
    
}
