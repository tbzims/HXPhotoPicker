//
//  AppearanceStyle.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public enum AppearanceStyle: Int {
    /// 跟随系统变化
    case varied = 0
    /// 正常风格，不会跟随系统变化
    case normal = 1
    /// 暗黑风格
    case dark = 2
}

/// 相册调取入口类型
public enum PhotoPickerEntranceType: Int {
    /// 聊天发送图片/视频
    case chatSend = 0
    /// 发布动态（发朋友圈/帖子等）
    case postFeed = 1
    /// 编辑个人头像
    case editAvatar = 2
    /// 评论/回复时添加图片
    case commentReply = 3
    /// 相册内扫描二维码
    case scanQrcodeInAlbum = 4
    /// 个人主页更换封面图
    case changeProfileCover = 5
    /// 通用场景
    case other = 6
    /// 发布动态时增加图片
    case addPostFeed = 7
}
