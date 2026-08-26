//
//  PhotoPreviewViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

private final class PreviewNavigationGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
        isUserInteractionEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class PhotoPreviewViewController: PhotoBaseViewController {
    
    weak var delegate: PhotoPreviewViewControllerDelegate?
    public let config: PreviewViewConfiguration
    /// 当前预览的位置索引
    public var currentPreviewIndex: Int = 0
    /// 预览的资源数组
    public var previewAssets: [PhotoAsset] = []
    public var previewType: PhotoPreviewType = .none
    public var collectionView: UICollectionView!
    /// 是否处于转场动画过程中
    public var isTransitioning: Bool = false
    public var navBgView: UIView?
    public var photoToolbar: PhotoToolBar!
    public var statusBarShouldBeHidden: Bool = false
    private let previewMediaContainerView = UIView()
    private let inputDimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        view.alpha = 0
        view.isUserInteractionEnabled = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    private var collectionViewLayout: UICollectionViewFlowLayout!
    var numberOfPages: PhotoBrowser.NumberOfPagesHandler?
    var cellForIndex: PhotoBrowser.CellReloadContext?
    var assetForIndex: PhotoBrowser.RequiredAsset?
    
    var selectBoxControl: SelectBoxView!
    var selectBoxItem: UIBarButtonItem!
    var interactiveTransition: PickerInteractiveTransition?
    weak var beforeNavDelegate: UINavigationControllerDelegate?
    var isPreviewSelect: Bool = false
    var orientationDidChange: Bool = false
    var viewDidAppear: Bool = false
    var firstLayoutSubviews: Bool = true
    var requestPreviewTimer: Timer?
    var isShowToolbar: Bool = false
    var assetCount: Int {
        if previewAssets.isEmpty {
            if let pages = numberOfPages?() {
                return pages
            }
            return 0
        }
        return previewAssets.count
    }
    var usesCustomMessageInput: Bool {
        pickerConfig.photoList.bottomView.customInputViewProvider != nil
    }
    var isCustomMessageInputExpanded = false
    private var isClosingPreview = false
    
    public var TMEditBtn: UIButton!
    public var TMOriginalBtn: UIButton!
    private let tmOriginalSelectedIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "hx_hd_done_yes"))
        imageView.isHidden = true
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    
    override init(config: PickerConfiguration) {
        self.config = config.previewView
        super.init(config: config)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if let photoToolbar = config.photoToolbar {
            isShowToolbar = photoToolbar.isShow(pickerConfig, type: previewType != .browser ? .preview : .browser)
        }else {
            isShowToolbar = config.isShowBottomView
        }
        title = ""
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.clipsToBounds = true
        initView()
    }
    
    public func photoAsset(for index: Int) -> PhotoAsset? {
        if !previewAssets.isEmpty, index >= 0, index < previewAssets.count {
            return previewAssets[index]
        }
        return assetForIndex?(index)
    }
    
    public override func updateColors() {
        if isTransitioning {
            return
        }
        if statusBarShouldBeHidden {
            view.backgroundColor = config.statusBarHiddenBgColor
        }else {
            view.backgroundColor = PhotoManager.isDark ?
                config.backgroundDarkColor :
                config.backgroundColor
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if usesCustomMessageInput {
            previewMediaContainerView.bounds = view.bounds
            previewMediaContainerView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        }
        let margin: CGFloat = 20
        let itemWidth = view.width + margin
        collectionViewLayout.minimumLineSpacing = margin
        collectionViewLayout.itemSize = view.size
        let contentWidth = (view.width + itemWidth) * CGFloat(assetCount)
        collectionView.frame = CGRect(x: -(margin * 0.5), y: 0, width: itemWidth, height: view.height)
        collectionView.contentSize = CGSize(width: contentWidth, height: view.height)
        collectionView.setContentOffset(CGPoint(x: CGFloat(currentPreviewIndex) * itemWidth, y: 0), animated: false)
        DispatchQueue.main.async {
            if self.orientationDidChange {
                let cell = self.getCell(for: self.currentPreviewIndex)
                cell?.setupScrollViewContentSize()
                self.orientationDidChange = false
            }
        }
        configBottomViewFrame()
        updateCurrentVideoSliderLayout()
        updateBottomGradientExtension()
        if firstLayoutSubviews {
            guard let photoAsset = photoAsset(for: currentPreviewIndex) else {
                return
            }
            DispatchQueue.main.async {
                self.photoToolbar.selectedViewScrollTo(photoAsset, animated: false)
            }
            firstLayoutSubviews = false
        }
        
        let navHeight: CGFloat
        if let navH = navigationController?.navigationBar.frame.maxY {
            navHeight = navH
        }else {
            navHeight = 0
        }
        navBgView?.frame = .init(x: 0, y: 0, width: view.width, height: navHeight)
        TMEditBtn.frame = CGRect(x: view.width - 56, y: view.height - UIScreen.main.bounds.size.height * 0.8, width: 44, height: 44)
        let originalButtonSize = CGSize(width: 60, height: 62)
        TMOriginalBtn.frame = CGRect(
            x: view.width - originalButtonSize.width,
            y: view.height - UIScreen.main.bounds.size.height * 0.8,
            width: originalButtonSize.width,
            height: originalButtonSize.height
        )
        updateTMOriginalButtonLayout()
        updateTMOriginalButtonVisibility(for: photoAsset(for: currentPreviewIndex))
    }
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        if let cell = getCell(for: currentPreviewIndex) {
            if cell.photoAsset.mediaSubType.isLivePhoto {
                if #available(iOS 9.1, *) {
                    cell.scrollContentView.livePhotoView.stopPlayback()
                }
            }
        }
    }
    public override func deviceOrientationDidChanged(notify: Notification) {
        photoToolbar.deviceOrientationDidChanged()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if usesCustomMessageInput {
            updateNavigationBarAppearance(isPreview: true)
        }
        if isShowToolbar {
            photoToolbar.viewWillAppear(self)
        }
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if usesCustomMessageInput {
            restorePreviewChrome()
        }
        viewDidAppear = true
        requestPreviewAsset()
        let isFullscreen = pickerController.modalPresentationStyle == .fullScreen || (splitViewController?.modalPresentationStyle == .fullScreen)
        let isMacApp: Bool
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            isMacApp = true
        }else {
            isMacApp = false
        }
        if ((isFullscreen && interactiveTransition == nil) ||
            (!UIDevice.isPortrait && !UIDevice.isPad) || isMacApp) && previewType != .browser {
            interactiveTransition = PickerInteractiveTransition(
                panGestureRecognizerFor: self,
                type: .pop
            )
        }
        if isShowToolbar {
            photoToolbar.viewDidAppear(self)
        }
        if config.isShowSelectBox == false {
            self.changeSelectBoxControlClick(isSelect: true)
        }
    }
    
    func requestPreviewAsset() {
        DispatchQueue.main.async {
            if let cell = self.getCell(for: self.currentPreviewIndex) {
                cell.requestPreviewAsset()
            }else {
                self.requestPreviewTimer = Timer.scheduledTimer(
                    withTimeInterval: 0.2,
                    repeats: false
                ) { [weak self] _ in
                    guard let self = self else { return }
                    let cell = self.getCell(for: self.currentPreviewIndex)
                    cell?.requestPreviewAsset()
                }
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isShowToolbar {
            photoToolbar.viewWillDisappear(self)
        }
        if config.isShowSelectBox == false {
            self.changeSelectBoxControlClick(isSelect: false)
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let viewControllers = navigationController?.viewControllers else {
            return
        }
        if !viewControllers.contains(self) {
            requestPreviewTimer?.invalidate()
            requestPreviewTimer = nil
        }
        if isShowToolbar {
            photoToolbar.viewDidDisappear(self)
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        statusBarShouldBeHidden
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if PhotoManager.isDark {
            return .lightContent
        }
        return pickerController.config.statusBarStyle
    }
    
    deinit {
        HXLog("PhotoPreviewViewController deinited 👍")
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Function
extension PhotoPreviewViewController {
     
    private func initView() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        collectionView = HXCollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        //        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        collectionView.register(PreviewPhotoViewCell.self)
        collectionView.register(PreviewLivePhotoViewCell.self)
        if let customVideoCell = config.customVideoCellClass {
            collectionView.register(
                customVideoCell,
                forCellWithReuseIdentifier: PreviewVideoViewCell.className
            )
        }else {
            collectionView.register(
                PreviewVideoViewCell.self,
                forCellWithReuseIdentifier: PreviewVideoViewCell.className
            )
        }
        if usesCustomMessageInput {
            previewMediaContainerView.frame = view.bounds
            previewMediaContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(previewMediaContainerView)
            previewMediaContainerView.addSubview(collectionView)
        } else {
            view.addSubview(collectionView)
        }

        if usesCustomMessageInput {
            inputDimmingView.frame = view.bounds
            inputDimmingView.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(didTapInputDimmingView))
            )
            view.addSubview(inputDimmingView)
        }
        
        initToolbar()
        
        selectBoxControl = SelectBoxView(
            config.selectBox,
            frame: CGRect(
                origin: .zero,
                size: config.selectBox.size
            )
        )
        selectBoxControl.backgroundColor = .clear
        selectBoxControl.addTarget(self, action: #selector(didSelectBoxControlClick), for: UIControl.Event.touchUpInside)
        
        selectBoxItem = .init(customView: selectBoxControl)
        
        if previewType != .none && pickerController.modalPresentationStyle != .custom {
            updateColors()
        }
        //        let cancelItem = UIBarButtonItem(
        //            image: imageType.image,
        //            style: .plain,
        //            target: self,
        //            action: #selector(didCancelItemClick)
        //        ).hidesShared()
        //        cancelItem.tintColor = .white
        //        navigationItem.leftBarButtonItem = cancelItem
        let btn = UIButton(type: .custom)
        //        btn.setImage(imageType.image, for: .normal)
        btn.setImage(
            UIImage(named: "common_back_white_2.1")?.withRenderingMode(.alwaysOriginal),
            for: .normal
        )
        btn.tintColor = .white
        btn.alpha = 1
        btn.addTarget(self, action: #selector(didCancelItemClick), for: .touchUpInside)
        
        // ✅ 扩大点击区域（关键：给按钮一个更大的frame + 内容居中）
        btn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 20)
        btn.contentHorizontalAlignment = .center
        btn.contentVerticalAlignment = .center
        
        let cancelItem = UIBarButtonItem(customView: btn).hidesShared()
        navigationItem.leftBarButtonItem = cancelItem
        if pickerConfig.isMultipleSelect || previewType != .browser {
            if previewType != .browser {
                if previewType == .picker {
                    //                    let cancelItem = UIBarButtonItem(
                    //                        image: imageType.image,
                    //                        style: .plain,
                    //                        target: self,
                    //                        action: #selector(didCancelItemClick)
                    //                    ).hidesShared()
                    //                    navigationItem.leftBarButtonItem = cancelItem
                    let btn = UIButton(type: .custom)
                    //                    btn.setImage(imageType.image, for: .normal)
                    btn.setImage(
                        UIImage(named: "common_back_white_2.1")?.withRenderingMode(.alwaysOriginal),
                        for: .normal
                    )
                    btn.tintColor = .white
                    btn.alpha = 1
                    btn.addTarget(self, action: #selector(didCancelItemClick), for: .touchUpInside)
                    
                    // ✅ 扩大点击区域（关键：给按钮一个更大的frame + 内容居中）
                    btn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                    btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 20)
                    btn.contentHorizontalAlignment = .center
                    btn.contentVerticalAlignment = .center
                    
                    let cancelItem = UIBarButtonItem(customView: btn).hidesShared()
                    navigationItem.leftBarButtonItem = cancelItem
                }
                if pickerConfig.isMultipleSelect {
                    navigationItem.rightBarButtonItem = selectBoxItem
                }
            }else {
                var cancelItem: UIBarButtonItem
                if config.cancelType == .image {
                    let isDark = PhotoManager.isDark
                    let item = UIBarButtonItem(
                        image: UIImage.image(
                            for: isDark ? config.cancelDarkImageName : config.cancelImageName
                        ),
                        style: .plain,
                        target: self,
                        action: #selector(didCancelItemClick)
                    )
                    if #available(iOS 26.0, *), !PhotoManager.isIos26Compatibility  {
                        cancelItem = item
                    }else {
                        cancelItem = item.hidesShared()
                    }
                }else {
                    let item = UIBarButtonItem(
                        title: .textPreview.cancelTitle.text,
                        style: .plain,
                        target: self,
                        action: #selector(didCancelItemClick)
                    )
                    if #available(iOS 26.0, *), !PhotoManager.isIos26Compatibility  {
                        cancelItem = item
                    }else {
                        cancelItem = item.hidesShared()
                    }
                }
                if config.cancelPosition == .left {
                    navigationItem.leftBarButtonItem = cancelItem
                } else {
                    navigationItem.rightBarButtonItem = cancelItem
                }
            }
            if assetCount > 0 && currentPreviewIndex == 0 {
                if let photoAsset = photoAsset(for: 0) {
                    if config.isShowBottomView {
                        photoToolbar.selectedViewScrollTo(photoAsset, animated: true)
                        
#if HXPICKER_ENABLE_EDITOR
                        if photoAsset.mediaType == .photo {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.isPhoto)
                        }else if photoAsset.mediaType == .video {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.contains(.video))
                        }
#endif
                    }
                    if previewType != .browser {
                        if photoAsset.mediaType == .video && pickerConfig.isSingleVideo {
                            if #available(iOS 16.0, *) {
                                selectBoxItem.isHidden = true
                            } else {
                                selectBoxControl.isHidden = true
                            }
                        } else {
                            updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                            selectBoxControl.isSelected = photoAsset.isSelected
                        }
                        if config.isShowSelectBox == false {
                            selectBoxControl.isHidden = true
                            if #available(iOS 16.0, *) {
                                selectBoxItem.isHidden = true
                            } else {
                                selectBoxItem = nil
                            }
                        }
                    }
                    pickerController.previewUpdateCurrentlyDisplayedAsset(
                        photoAsset: photoAsset,
                        index: currentPreviewIndex
                    )
                }
            }
        }else if !pickerConfig.isMultipleSelect {
            if previewType == .picker {
                //                let cancelItem = UIBarButtonItem(
                //                    image: .imageResource.picker.preview.cancel.image,
                //                    style: .plain,
                //                    target: self,
                //                    action: #selector(didCancelItemClick)
                //                ).hidesShared()
                //                navigationItem.leftBarButtonItem = cancelItem
                let btn = UIButton(type: .custom)
                btn.setImage(
                    UIImage(named: "common_back_white_2.1")?.withRenderingMode(.alwaysOriginal),
                    for: .normal
                )
                btn.tintColor = .white
                btn.alpha = 1
                btn.addTarget(self, action: #selector(didCancelItemClick), for: .touchUpInside)
                
                // ✅ 扩大点击区域（关键：给按钮一个更大的frame + 内容居中）
                btn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 20)
                btn.contentHorizontalAlignment = .center
                btn.contentVerticalAlignment = .center
                
                let cancelItem = UIBarButtonItem(customView: btn).hidesShared()
                navigationItem.leftBarButtonItem = cancelItem
            }
            if assetCount > 0 && currentPreviewIndex == 0 {
                if let photoAsset = photoAsset(for: 0) {
#if HXPICKER_ENABLE_EDITOR
                    if config.isShowBottomView {
                        if photoAsset.mediaType == .photo {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.isPhoto)
                        }else if photoAsset.mediaType == .video {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.contains(.video))
                        }
                    }
#endif
                    pickerController.previewUpdateCurrentlyDisplayedAsset(
                        photoAsset: photoAsset,
                        index: currentPreviewIndex
                    )
                }
            }
        }
        if (!pickerConfig.adaptiveBarAppearance || usesCustomMessageInput), previewType != .browser {
            let navBgView = PreviewNavigationGradientView()
            view.addSubview(navBgView)
            self.navBgView = navBgView
        }
        
        //强制LTR，避免阿语下预览图片内容被镜像
        view.semanticContentAttribute = .forceLeftToRight
        collectionView.semanticContentAttribute = .forceLeftToRight
        
        //自定义编辑按钮
        TMEditBtn = UIButton(type: .custom)
        TMEditBtn.setImage(.imageResource.editor.tools.tmEditImg.image, for: .normal)
        TMEditBtn.addTarget(self, action: #selector(TMEditBtnAction), for: .touchUpInside)
        view.addSubview(TMEditBtn)
        TMEditBtn.isHidden = true
        TMOriginalBtn = UIButton(type: .custom)
        TMOriginalBtn.setImage(UIImage(named: "icon_24_hd_big"), for: .normal)
        TMOriginalBtn.setImage(UIImage(named: "icon_24_hd_fill_big"), for: .selected)
        TMOriginalBtn.setTitle(config.qualityStr, for: .normal)
        TMOriginalBtn.setTitleColor(.white, for: .normal)
        TMOriginalBtn.setTitleColor(.white, for: .selected)
        TMOriginalBtn.addTarget(self, action: #selector(TMOriginalBtnAction), for: .touchUpInside)
        TMOriginalBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        TMOriginalBtn.titleLabel?.textAlignment = .center
        TMOriginalBtn.titleLabel?.lineBreakMode = .byTruncatingTail
        TMOriginalBtn.titleLabel?.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        TMOriginalBtn.titleLabel?.layer.shadowOpacity = 1
        TMOriginalBtn.titleLabel?.layer.shadowRadius = 4
        TMOriginalBtn.titleLabel?.layer.shadowOffset = .zero
        TMOriginalBtn.titleLabel?.layer.masksToBounds = false
        TMOriginalBtn.imageView?.contentMode = .scaleAspectFit
        TMOriginalBtn.contentHorizontalAlignment = .center
        TMOriginalBtn.contentVerticalAlignment = .center
        TMOriginalBtn.clipsToBounds = false
        TMOriginalBtn.addSubview(tmOriginalSelectedIconView)
        view.addSubview(TMOriginalBtn)
        updateTMOriginalButtonState(pickerController.isOriginal)
        updateTMOriginalButtonLayout()
        updateTMOriginalButtonVisibility(for: photoAsset(for: currentPreviewIndex))
    }
    
    @objc func TMOriginalBtnAction() {
        TMOriginalBtn.isSelected.toggle()
        updateTMOriginalButtonState(TMOriginalBtn.isSelected)
        self.setOriginal(TMOriginalBtn.isSelected)
    }

    func updateTMOriginalButtonVisibility(for photoAsset: PhotoAsset?) {
        guard TMOriginalBtn != nil else {
            return
        }
        guard !isClosingPreview else {
            TMOriginalBtn.isHidden = true
            return
        }
        guard let photoAsset else {
            TMOriginalBtn.isHidden = true
            return
        }
        TMOriginalBtn.isHidden = photoAsset.mediaType == .video || photoAsset.isGifAsset
    }

    func updateTMOriginalButtonLayout() {
        guard let imageView = TMOriginalBtn.imageView,
              let titleLabel = TMOriginalBtn.titleLabel else {
            return
        }
        TMOriginalBtn.layoutIfNeeded()
        let imageSize = imageView.image?.size ?? CGSize(width: 24, height: 24)
        let titleSize = titleLabel.intrinsicContentSize
        let spacing: CGFloat = 1
        TMOriginalBtn.imageEdgeInsets = UIEdgeInsets(
            top: -(titleSize.height + spacing),
            left: 0,
            bottom: 0,
            right: -titleSize.width
        )
        TMOriginalBtn.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageSize.width,
            bottom: -(imageSize.height + spacing),
            right: 0
        )
        let verticalInset = max(0, (titleSize.height + spacing) * 0.5)
        TMOriginalBtn.contentEdgeInsets = UIEdgeInsets(
            top: verticalInset,
            left: 0,
            bottom: verticalInset,
            right: 0
        )
        TMOriginalBtn.layoutIfNeeded()
        tmOriginalSelectedIconView.bounds = CGRect(x: 0, y: 0, width: 16, height: 16)
        tmOriginalSelectedIconView.center = CGPoint(
            x: imageView.frame.maxX - 14,
            y: imageView.frame.maxY - 14
        )
        TMOriginalBtn.bringSubviewToFront(tmOriginalSelectedIconView)
    }

    func updateTMOriginalButtonState(_ isOriginal: Bool) {
        guard TMOriginalBtn != nil else { return }
        TMOriginalBtn.isSelected = isOriginal
        tmOriginalSelectedIconView.isHidden = !isOriginal
        TMOriginalBtn.accessibilityValue = isOriginal ? "On" : "Off"
    }
    
    @objc func TMEditBtnAction() {
        self.photoToolbar(didEditClick: self.photoToolbar)
    }
    
    func configBottomViewFrame() {
        if !config.isShowBottomView {
            return
        }
        let bottomHeight = photoToolbar.viewHeight
        photoToolbar.frame = CGRect(
            x: 0,
            y: view.height - bottomHeight,
            width: view.width,
            height: bottomHeight
        )
    }

    func updateInputPresentation(
        isExpanded: Bool,
        keyboardOffset: CGFloat,
        duration: TimeInterval,
        options: UIView.AnimationOptions
    ) {
        guard usesCustomMessageInput else { return }
        isCustomMessageInputExpanded = isExpanded
        updateBottomGradientExtension()
        inputDimmingView.isUserInteractionEnabled = isExpanded
        let upwardOffset = isExpanded ? min(80, max(56, keyboardOffset * 0.22)) : 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [options, .beginFromCurrentState, .allowUserInteraction]
        ) {
            self.inputDimmingView.alpha = isExpanded ? 1 : 0
            self.previewMediaContainerView.transform = CGAffineTransform(
                translationX: 0,
                y: -upwardOffset
            )
            // 输入框展开时同步渐隐顶部导航和原图质量按钮，收起时恢复显示。
            let topControlsAlpha: CGFloat = isExpanded ? 0 : 1
            self.navigationController?.navigationBar.alpha = topControlsAlpha
            self.navBgView?.alpha = topControlsAlpha
            self.TMOriginalBtn?.alpha = topControlsAlpha
            self.updateCurrentVideoSliderLayout()
        }
    }

    func updateCurrentVideoSliderLayout() {
        guard usesCustomMessageInput else { return }
        for case let cell as PreviewVideoControlViewCell in collectionView.visibleCells {
            updateVideoSliderLayout(for: cell)
        }
    }

    func updateVideoSliderLayout(for cell: PreviewVideoControlViewCell) {
        guard usesCustomMessageInput else { return }
        let sliderHeight: CGFloat = 56
        let sliderBottom = photoToolbar.frame.minY
        cell.sliderView.frame = CGRect(
            x: 0,
            y: sliderBottom - sliderHeight,
            width: cell.bounds.width,
            height: sliderHeight
        )
        cell.isExternalSliderHidden = isCustomMessageInputExpanded
        cell.sliderView.isHidden = isCustomMessageInputExpanded
        cell.sliderView.alpha = isCustomMessageInputExpanded ? 0 : 1
        cell.maskBackgroundView.frame = cell.sliderView.frame
        cell.maskLayer.frame = CGRect(
            x: 0,
            y: -20,
            width: cell.bounds.width,
            height: cell.maskBackgroundView.bounds.height + 20
        )
    }

    func updateBottomGradientExtension() {
        guard usesCustomMessageInput else { return }
        let isVideo = photoAsset(for: currentPreviewIndex)?.mediaType == .video
        let extensionHeight: CGFloat = isVideo && !isCustomMessageInputExpanded ? 106 : 0
        photoToolbar.updateCustomInputBottomGradientExtension(extensionHeight)
    }

    @objc
    private func didTapInputDimmingView() {
        photoToolbar.dismissCustomInput()
    }

    func updateNavigationBarAppearance(isPreview: Bool) {
        guard let navigationBar = navigationController?.navigationBar else { return }
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            if isPreview {
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
            } else {
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = pickerConfig.navigationViewBackgroundColor
            }
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        } else {
            navigationBar.setBackgroundImage(isPreview ? UIImage() : nil, for: .default)
            navigationBar.shadowImage = UIImage()
        }
        navigationBar.isTranslucent = isPreview
    }

    func restorePreviewChrome() {
        guard !statusBarShouldBeHidden else { return }
        navigationController?.setNavigationBarHidden(false, animated: false)
        updateNavigationBarAppearance(isPreview: true)
        navigationController?.navigationBar.layer.removeAllAnimations()
        navigationController?.navigationBar.alpha = 1
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
        navBgView?.layer.removeAllAnimations()
        navBgView?.isHidden = false
        navBgView?.alpha = 1
        photoToolbar.layer.removeAllAnimations()
        photoToolbar.isHidden = false
        photoToolbar.alpha = 1
    }
    func reloadCell(for item: Int) {
        guard let photoAsset = photoAsset(for: item) else {
            return
        }
        let indexPath = IndexPath(item: item, section: 0)
        collectionView.reloadItems(at: [indexPath])
        if item == currentPreviewIndex {
            updateTMOriginalButtonVisibility(for: photoAsset)
        }
        if config.isShowBottomView {
            photoToolbar.reloadSelectedAsset(photoAsset)
            photoToolbar.requestOriginalAssetBtyes()
        }
    }
    func getCell(for item: Int) -> PhotoPreviewViewCell? {
        if assetCount == 0 {
            return nil
        }
        let cell = collectionView.cellForItem(
            at: IndexPath(
                item: item,
                section: 0
            )
        ) as? PhotoPreviewViewCell
        return cell
    }
//    func getCell(for photoAsset: PhotoAsset) -> PhotoPreviewViewCell? {
//        guard let item = previewAssets.firstIndex(of: photoAsset) else {
//            return nil
//        }
//        return getCell(for: item)
//    }
    func scrollToPhotoAsset(_ photoAsset: PhotoAsset) {
        guard let index = previewAssets.firstIndex(of: photoAsset) else {
            return
        }
        scrollToItem(index)
    }
    func scrollToItem(_ item: Int, animated: Bool = false) {
        if item == currentPreviewIndex {
            return
        }
        getCell(for: currentPreviewIndex)?.cancelRequest()
        collectionView.scrollToItem(
            at: IndexPath(item: item, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
        startRequestPreviewTimer()
    }
    public func setCurrentCellImage(image: UIImage?) {
        guard let image = image,
              let cell = getCell(for: currentPreviewIndex),
              !cell.scrollContentView.requestCompletion else {
            return
        }
        cell.scrollContentView.imageView.image = image
    }
    func insert(at item: Int) {
        if item == currentPreviewIndex {
            getCell(for: item)?.cancelRequest()
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
            collectionView.scrollToItem(
                at: IndexPath(
                    item: item,
                    section: 0
                ),
                at: .centeredHorizontally,
                animated: false
            )
            scrollViewDidScroll(collectionView)
            startRequestPreviewTimer()
        }else {
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
        }
    }
    func insert(_ photoAsset: PhotoAsset, at item: Int) {
        if previewAssets.isEmpty {
            return
        }
        if isShowToolbar {
            photoToolbar.previewListInsert(photoAsset, at: item)
        }
        previewAssets.insert(photoAsset, at: item)
        if item == currentPreviewIndex {
            getCell(for: item)?.cancelRequest()
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
            collectionView.scrollToItem(
                at: IndexPath(
                    item: item,
                    section: 0
                ),
                at: .centeredHorizontally,
                animated: false
            )
            scrollViewDidScroll(collectionView)
            startRequestPreviewTimer()
        }else {
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
        }
        
    }
    func deleteItems(at items: [Int]) {
        if assetCount == 0 || previewType != .browser || items.isEmpty {
            return
        }
        var indexPaths: [IndexPath] = []
        var photoAssets: [PhotoAsset] = []
        for item in items {
            guard let photoAsset = photoAsset(for: item) else {
                continue
            }
            let shouldDelete = pickerController.previewShouldDeleteAsset(
                photoAsset: photoAsset,
                index: item
            )
            if !shouldDelete {
                continue
            }
            #if HXPICKER_ENABLE_EDITOR
            photoAsset.editedResult = nil
            #endif
            if let index = previewAssets.firstIndex(of: photoAsset) {
                previewAssets.remove(at: index)
            }
            indexPaths.append(.init(
                item: item,
                section: 0
            ))
            photoAssets.append(photoAsset)
        }
        collectionView.deleteItems(at: indexPaths)
        if isShowToolbar {
            photoToolbar.removeSelectedAssets(photoAssets)
            photoToolbar.previewListRemove(photoAssets)
        }
        pickerController.pickerDelegate?.pickerController(
            pickerController,
            previewDidDeleteAssets: photoAssets,
            at: items
        )
        if assetCount > 0 {
            scrollViewDidScroll(collectionView)
            startRequestPreviewTimer()
        }else {
            didCancelItemClick()
        }
    }
    func deleteCurrentPhotoAsset() {
        deleteItems(at: [currentPreviewIndex])
    }
    func replacePhotoAsset(at index: Int, with photoAsset: PhotoAsset) {
        previewAssets[index] = photoAsset
        reloadCell(for: index)
//        collectionView.reloadItems(at: [IndexPath.init(item: index, section: 0)])
    }
    func addedCameraPhotoAsset(_ photoAsset: PhotoAsset) {
        if isShowToolbar {
            photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
            configBottomViewFrame()
            photoToolbar.layoutSubviews()
            photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
            photoToolbar.previewListInsert(photoAsset, at: currentPreviewIndex)
        }
        getCell(for: currentPreviewIndex)?.cancelRequest()
        previewAssets.insert(
            photoAsset,
            at: currentPreviewIndex
        )
        collectionView.insertItems(
            at: [
                IndexPath(
                    item: currentPreviewIndex,
                    section: 0
                )
            ]
        )
        collectionView.scrollToItem(
            at: IndexPath(
                item: currentPreviewIndex,
                section: 0
            ),
            at: .centeredHorizontally,
            animated: false
        )
        scrollViewDidScroll(collectionView)
        startRequestPreviewTimer()
    }
    
    @objc func didCancelItemClick() {
//        pickerController.cancelCallback()
        isClosingPreview = true
        TMOriginalBtn.layer.removeAllAnimations()
        TMOriginalBtn.alpha = 0
        TMOriginalBtn.isHidden = true
        if let viewControllers = navigationController?.viewControllers,
           viewControllers.count > 1 {
            navigationController?.popViewController(animated: true)
        }else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func removeSelectedAssetWhenRemovingAssets(_ assets: [PhotoAsset]) {
        if assetCount == 0 || assets.isEmpty {
            return
        }
        var indexPaths: [IndexPath] = []
        let tempAssets = previewAssets
        for photoAsset in assets {
            guard let index = previewAssets.firstIndex(of: photoAsset) else {
                continue
            }
            previewAssets.remove(at: index)
            if let index = tempAssets.firstIndex(of: photoAsset) {
                indexPaths.append(.init(
                    item: index,
                    section: 0
                ))
            }
        }
        collectionView.deleteItems(at: indexPaths)
        if isShowToolbar {
            photoToolbar.previewListRemove(assets)
            photoToolbar.removeSelectedAssets(assets)
            photoToolbar.requestOriginalAssetBtyes()
            photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
            if pickerController.selectedAssetArray.isEmpty {
                UIView.animate(withDuration: 0.25) {
                    self.configBottomViewFrame()
                    self.photoToolbar.layoutSubviews()
                }
            }
        }
        if assetCount > 0 {
            scrollViewDidScroll(collectionView)
            startRequestPreviewTimer()
        }else {
            if let viewControllers = navigationController?.viewControllers,
               viewControllers.count > 1 {
                navigationController?.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func updateAsstes(for assets: [PhotoAsset]) {
        previewAssets = assets
        collectionView.reloadData()
        let count = assetCount
        if count > 0 {
            var page = currentPreviewIndex
            if page > count - 1 {
                DispatchQueue.main.async {
                    self.scrollToItem(count - 1)
                }
                page = count - 1
            }else {
                DispatchQueue.main.async {
                    self.scrollViewDidScroll(self.collectionView)
                    self.startRequestPreviewTimer()
                }
            }
            if isShowToolbar {
                photoToolbar.configPreviewList(assets, page: page)
                configBottomViewFrame()
            }
        }else {
            if let viewControllers = navigationController?.viewControllers,
               viewControllers.count > 1 {
                navigationController?.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    public var transitionCellView: PhotoPreviewViewCell? {
        guard let cell = getCell(for: currentPreviewIndex) else {
            return nil
        }
        return cell
    }
}
