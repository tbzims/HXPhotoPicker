//
//  EmptyViewConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 照片列表空资源时展示的视图
public struct EmptyViewConfiguration {
    
    /// 标题颜色
    public var titleColor: UIColor = UIColor(hexString: "#FFFFFF")
    
    public var titleFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    
    /// 暗黑风格下标题颜色
    public var titleDarkColor: UIColor = "#ffffff".hx.color
    
    /// 子标题颜色
    public var subTitleColor: UIColor = UIColor(hexString: "#FFFFFF").withAlphaComponent(0.64)
    
    public var subTitleFont: UIFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    
    /// 暗黑风格下子标题颜色
    public var subTitleDarkColor: UIColor = "#dadada".hx.color
    
    public var titleStr: String = "No data available"
    
    public var subStr: String = "There is currently no content here"
    
    public var emptyLottieView: UIView?
        
    public init() { }
}
