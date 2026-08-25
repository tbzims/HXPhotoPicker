//
//  PhotoPickerViewController+Toolbar.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

extension PhotoPickerViewController: PhotoToolBarDelegate {
    
    func initToolbar() {
        if AssetPermissionsUtil.authorizationStatus == .notDetermined {
            photoToolbar = PhotoToolBarEmptyView(pickerConfig, type: .picker)
            return
        }
        if photoToolbar?.superview == view || (photoToolbar?.superview == bottomContainerView && bottomContainerView != nil) {
            return
        }
        if !isShowToolbar {
            photoToolbar = PhotoToolBarEmptyView(pickerConfig, type: .picker)
            return
        }
        guard let toolbar = config.photoToolbar else {
            return
        }
        photoToolbar = toolbar.init(pickerConfig, type: .picker)
        photoToolbar.toolbarDelegate = self
        photoToolbar.configureCustomInput(text: pickerController.albumMessageText) { [weak self] text in
            self?.pickerController.updateAlbumMessageText(text)
        }
        photoToolbar.updateOriginalState(pickerController.isOriginal)
        if let bottomContainerView {
            bottomContainerView.addSubview(photoToolbar)
        }else {
            view.addSubview(photoToolbar)
        }
        if pickerConfig.isMultipleSelect {
            if pickerController.isOriginal {
                photoToolbar.requestOriginalAssetBtyes()
            }
            photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
            photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
        }
    }
    
    func updateToolbarFrame() {
        if photoToolbar.viewHeight != photoToolbar.height {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction]
            ) {
                self.layoutToolbar()
                self.photoToolbar.setNeedsLayout()
                self.photoToolbar.layoutIfNeeded()
            }
        }
    }

    public func photoToolbarDidUpdateHeight(_ toolbar: PhotoToolBar) {
        updateToolbarFrame()
    }
    
    func requestSelectedAssetFileSize() {
        pickerController.pickerData.requestSelectedAssetFileSize(isPreview: false, completion: { [weak self] in
            self?.photoToolbar.originalAssetBytes($0, bytesString: $1)
        })
    }
    
    public func photoToolbar(didPreviewClick toolbar: PhotoToolBar) {
        if pickerController.selectedAssetArray.isEmpty {
            return
        }
        pushPreviewViewController(
            previewAssets: pickerController.selectedAssetArray,
            currentPreviewIndex: 0,
            isPreviewSelect: true,
            animated: true
        )
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didOriginalClick isSelected: Bool) {
        pickerController.config.isSelectedOriginal = isSelected
        pickerController.isOriginal = isSelected
        updateHDNavigationItem(isOriginal: isSelected)
        pickerController.originalButtonCallback()
        if isSelected {
            requestSelectedAssetFileSize()
        } else {
            pickerController.pickerData.cancelRequestAssetFileSize(isPreview: false)
        }
    }
    
    public func photoToolbar(didFinishClick toolbar: PhotoToolBar) {
        pickerController.finishCallback()
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didSelectedAsset asset: PhotoAsset) {
        let previewAssets = pickerController.selectedAssetArray
        let index = previewAssets.firstIndex(of: asset) ?? 0
        pushPreviewViewController(
            previewAssets: pickerController.selectedAssetArray,
            currentPreviewIndex: index,
            isPreviewSelect: true,
            animated: true
        )
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didMoveAsset fromIndex: Int, with toIndex: Int) {
        pickerController.pickerData.move(fromIndex: fromIndex, toIndex: toIndex)
        photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
        listView.updateCellSelectedTitle()
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didDeleteAsset asset: PhotoAsset) {
        deselectedAsset(asset)
    }
    
    public func deselectedAsset(_ asset: PhotoAsset) {
        pickerController.pickerData.remove(asset)
        #if HXPICKER_ENABLE_EDITOR
        if asset.videoEditedResult != nil, pickerConfig.isDeselectVideoRemoveEdited {
            asset.editedResult = nil
        }else if asset.photoEditedResult != nil, pickerConfig.isDeselectPhotoRemoveEdited {
            asset.editedResult = nil
        }
        #endif
        listView.updateCellSelectedTitle()
        photoToolbar.removeSelectedAssets([asset])
        if pickerController.isOriginal {
            photoToolbar.requestOriginalAssetBtyes()
        }
        photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
        updateToolbarFrame()
    }
    
    public func setOriginal(_ isOriginal: Bool) {
        guard let photoToolbar = photoToolbar else {
            return
        }
        photoToolbar.updateOriginalState(isOriginal)
        if !isOriginal {
            pickerController.pickerData.cancelRequestAssetFileSize(isPreview: false)
        } else {
            requestSelectedAssetFileSize()
        }
        pickerController.config.isSelectedOriginal = isOriginal
        pickerController.isOriginal = isOriginal
        updateHDNavigationItem(isOriginal: isOriginal)
        pickerController.originalButtonCallback()
    }
}
