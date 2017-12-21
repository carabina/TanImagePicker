//
//  ImageCell.swift
//  TanImagePicker
//
//  Created by Tangent on 19/12/2017.
//  Copyright © 2017 Tangent. All rights reserved.
//

import UIKit
import Photos

extension TanImagePicker {
    final class ImageCell: UICollectionViewCell, ReusableView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UI.backgroundColor
            contentView.addSubview(_imageView)
            contentView.addSubview(_playerView)
            contentView.addSubview(_progressView)
            contentView.addSubview(_checkView)
            contentView.addSubview(_videoMarkView)
        }
        
        deinit {
            _clear()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private let _imageView: UIImageView = {
            $0.clipsToBounds = true
            $0.contentMode = .scaleAspectFill
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return $0
        }(UIImageView())
        
        private let _checkView: _CheckView = {
            $0.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
            $0.isHidden = true
            return $0
        }(_CheckView())
        
        private let _videoMarkView: UIImageView = {
            $0.sizeToFit()
            $0.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            $0.isHidden = true
            $0.tintColor = .white
            return $0
        }(UIImageView(image: UIImage(named: "video")?.withRenderingMode(.alwaysTemplate)))
        
        private let _playerView: _PlayeView = {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0.isHidden = true
            return $0
        }(_PlayeView())
        
        private let _progressView: _ProgressView = {
            $0.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
            $0.isHidden = true
            return $0
        }(_ProgressView())
        
        // For Image
        private var _imageRequestID: PHImageRequestID?
        // For Video
        private var _videoRequestID: PHImageRequestID?
        private var _isScrolling = true
        
        var isContentViewCell: Bool = true
        
        var item: ImageItem? {
            didSet {
                guard let item = item else { return }
                _beginFetchImage(item)
                _beginFetchVideo(item)
                _bindItem(item)
            }
        }
    }
}

extension TanImagePicker.ImageCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        _imageView.frame = bounds
        _checkView.frame.origin.x = bounds.width - Me.UI.checkViewHorizontalMargin() - _checkView.bounds.width
        _checkView.frame.origin.y = bounds.height - Me.UI.checkViewBottomMargin() - _checkView.bounds.height
        _videoMarkView.frame.origin.y = bounds.height - Me.UI.videoMarkViewBottomMargin() - _videoMarkView.bounds.height
        _videoMarkView.frame.origin.x = Me.UI.videoMarkVideLeftMargin()
        _playerView.frame = bounds
        _progressView.center = _playerView.center
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        _clear()
    }
}

private extension TanImagePicker.ImageCell {
    func _unbindItem(_ item: Me.ImageItem) {
        guard isContentViewCell, item.bindedCell === self else { return }
        item.selectedStateCallback = nil
        item.canSelectedCallback = nil
    }
    
    func _bindItem(_ item: Me.ImageItem) {
        guard isContentViewCell else { return }
        _checkView.refresh(isSelected: item.isSelected)
        _checkView.isHidden = !item.canSelected
        _videoMarkView.isHidden = !item.isVideo
        _progressView.isHidden = !item.isVideo
        
        item.selectedStateCallback = { [weak self] in
            self?._checkView.refresh(isSelected: $0)
        }
        item.canSelectedCallback = { [weak self] in
            self?._checkView.isHidden = !$0
        }
        item.bindedCell = self
    }
    
    func _beginFetchVideo(_ item: Me.ImageItem) {
        guard item.isVideo, Me.UI.automaticallyFetchVideoIfHas else { return }
        _videoRequestID = Me.ImagesManager.shared.fetchVideo(with: item.asset, progressHandler: { [weak self] progress, _ in
            Me.mainQueue.async {
                self?._progressView.progress = progress
            }
        }, completionHandler: { [weak self] video in
            Me.mainQueue.async {
                self?._progressView.isHidden = true
                self?._playerView.isHidden = false
                self?._playerView.video = video
                if self?.isContentViewCell == false || self?._isScrolling == false {
                    self?._playerView.play()
                }
            }
        })
    }
    
    func _cancelVideoFetching() {
        _playerView.isHidden = true
        if let videoRequestID = _videoRequestID {
            PHImageManager.default().cancelImageRequest(videoRequestID)
        }
        _playerView.clear()
    }
    
    func _beginFetchImage(_ item: Me.ImageItem) {
        _imageRequestID = Me.ImagesManager.shared.fetchImage(with: item.asset, type: .thumbnail(size: bounds.size)) { [weak self] in
            self?._imageView.image = $0
        }
    }
    
    func _cancalImageFecthing() {
        if let imageRequestID = _imageRequestID {
            PHImageManager.default().cancelImageRequest(imageRequestID)
        }
        _imageView.image = nil
    }
    
    func _clear() {
        if let oldItem = item { _unbindItem(oldItem) }
        _cancalImageFecthing()
        _cancelVideoFetching()
    }
}

// Listen ContentView Scrolling
extension TanImagePicker.ImageCell {
    private func _layoutCheckViewWithMaxX(_ x: CGFloat) {
        _checkView.frame.origin.x = x - Me.UI.checkViewHorizontalMargin() - _checkView.bounds.width
    }
    
    func scrolling(collectionView: UICollectionView) {
        guard let superview = superview else { return }
        let cellFrame = collectionView.convert(frame, from: superview)
        let maxX = min(cellFrame.maxX, collectionView.bounds.maxX) - cellFrame.origin.x
        let magicMarginNumber: CGFloat = 6
        guard maxX > Me.UI.checkViewHorizontalMargin() + _checkView.bounds.width + magicMarginNumber else { return }
        _layoutCheckViewWithMaxX(maxX)
    }
    
    func switchScrollingState(isScrolling: Bool) {
        guard isContentViewCell else { return }
        _isScrolling = isScrolling
        if isScrolling {
            _playerView.pause()
        } else {
            _playerView.play()
        }
    }
}

// MARK: - CheckView
private let imageMark = UIImage(named: "image_mark")
private let imageMarkSel = UIImage(named: "image_mark_sel")
private extension TanImagePicker.ImageCell {
    final class _CheckView: UIImageView {
        init() {
            super.init(image: imageMark)
            setNeedsLayout()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func refresh(isSelected: Bool) {
            image = isSelected ? imageMarkSel : imageMark
        }
    }
}

// MARK: - PlayerView
private extension TanImagePicker.ImageCell {
    final class _PlayeView: UIView {
        private lazy var _player: AVPlayer = {
            let player = AVPlayer()
            player.isMuted = true
            return player
        }()
        
        private lazy var _playerLayer: AVPlayerLayer = {
            let layer = AVPlayerLayer(player: $0)
            layer.videoGravity = .resizeAspectFill
            return layer
        }(_player)
        
        init() {
            super.init(frame: .zero)
            layer.addSublayer(_playerLayer)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            _playerLayer.frame = bounds
        }
        
        var video: AVAsset?
    }
}

extension TanImagePicker.ImageCell._PlayeView {
    func play() {
        if _player.currentItem != nil {
            _player.play()
        } else if let mVideo = video {
            mVideo.loadValuesAsynchronously(forKeys: ["playable"], completionHandler: { [weak self] in
                let item = AVPlayerItem(asset: mVideo)
                self?._player.replaceCurrentItem(with: item)
                self?._loopToPlay(item: item)
                self?._player.play()
            })
        }
    }
    
    func pause() {
        _player.pause()
    }
    
    var isPause: Bool {
        return _player.rate == 0
    }
    
    func clear() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        _player.replaceCurrentItem(with: nil)
        video = nil
    }
}

private extension TanImagePicker.ImageCell._PlayeView {
    func _loopToPlay(item: AVPlayerItem) {
        NotificationCenter.default.addObserver(self, selector: #selector(TanImagePicker.ImageCell._PlayeView._playBack), name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    
    @objc func _playBack() {
        _player.seek(to: kCMTimeZero)
        play()
    }
}

// MARK: - ProgressView
private let progressViewSize = CGSize(width: 2 * Me.UI.cellProgressViewRadius(), height: 2 * Me.UI.cellProgressViewRadius())
private extension TanImagePicker.ImageCell {
    final class _ProgressView: UIView {
        var progress: Double = 0 {
            didSet {
                _shapeLayer.strokeEnd = min(1, max(0, CGFloat(progress)))
            }
        }
        
        init() {
            super.init(frame: CGRect(origin: .zero, size: progressViewSize))
            layer.addSublayer(_shapeLayer)
            _shapeLayer.path = _path
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowRadius = 1.8
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 1, height: 1)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private let _path: CGPath = {
            let center = CGPoint(x: 0.5 * progressViewSize.width, y: 0.5 * progressViewSize.height)
            return UIBezierPath(arcCenter: center, radius: Me.UI.cellProgressViewRadius(), startAngle: -0.5 * CGFloat.pi, endAngle: 1.5 * CGFloat.pi, clockwise: true).cgPath
        }()
        
        private let _shapeLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.lineCap = kCALineCapRound
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = UIColor.white.cgColor
            layer.strokeStart = 0
            layer.strokeEnd = 0
            layer.zPosition = 1
            layer.lineWidth = Me.UI.cellProgressViewLineWidth()
            return layer
        }()
        
        override func layoutSubviews() {
            super.layoutSubviews()
            _shapeLayer.frame = bounds
        }
    }
}
