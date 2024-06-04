//
//  PreviewImageTableViewCell.swift
//  FireApp
//
//  Created by Devlomi on 7/13/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import ImageScrollView
import AVFoundation

enum VideoStatus {
    case playing, paused, stopped, finished
}
protocol VideoPlayerDelegate {
    func didUpdate(currentProgress: CMTime, duration: CMTime?)
    func didStatusChange(status: VideoStatus)
    func mainViewTapped()
}


class PreviewImageCollectionViewCell: UICollectionViewCell, UIGestureRecognizerDelegate {


    private var currentVideoPath: String = ""


    var videoViewsStackview: UIStackView!
    var delegate: VideoPlayerDelegate?

    var player: AVPlayer?


    @IBOutlet weak var videoImage: UIImageView!

    @IBOutlet weak var playBtn: UIButton!

    @IBOutlet weak var previewImage: ImageScrollView!

    @IBAction func playBtnTapped(_ sender: Any) {
        
        guard let player = self.player else {
            //video not played before
            playVideo()
            return
        }


        if player.isPlaying {
            pauseVideo()
        } else {
            startPlaying()
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)


    }

    fileprivate func setupHero(_ message: Message, _ viewBounds: CGRect, isPreviewImageView: Bool) {

        if isPreviewImageView {

            videoImage.hero.isEnabled = false
            previewImage.hero.isEnabled = true
            previewImage.hero.id = message.messageId
            previewImage.hero.modifiers = [.position(CGPoint(x: viewBounds.width / 2, y: viewBounds.height + viewBounds.width / 2)), .scale(0.6), .fade]
        } else {
            previewImage.hero.isEnabled = false
            videoImage.hero.isEnabled = true

            videoImage.hero.id = message.messageId
            videoImage.hero.isEnabled = true
            videoImage.hero.modifiers = [.position(CGPoint(x: viewBounds.width / 2, y: viewBounds.height + viewBounds.width / 2)), .scale(0.6), .fade]

        }

    }

    func bind(message: Message, viewBounds: CGRect) {

        if message.typeEnum.isImage() {

            previewImage.isHidden = false
            videoImage.isHidden = true


            previewImage.setup()
            previewImage.imageContentMode = .aspectFit
            previewImage.initialOffset = .center
            setupHero(message, viewBounds, isPreviewImageView: true)

            previewImage.isOpaque = true

            if let image = UIImage(contentsOfFile: message.localPath) {
                previewImage.display(image: image)

            }

            playBtn.isHidden = true
        } else if message.typeEnum.isVideo() {

            currentVideoPath = message.localPath

            previewImage.isHidden = true
            videoImage.isHidden = false



            if !message.videoThumb.isEmpty {
                let image = message.videoThumb.toUIImage()
                videoImage.image = image
            }

            setupHero(message, viewBounds, isPreviewImageView: false)
            videoImage.isOpaque = true



            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewClicked))
            tapGesture.delegate = self
            contentView.addGestureRecognizer(tapGesture)


            playBtn.isHidden = false
            playBtn.setImage(#imageLiteral(resourceName: "play_circle"), for: .normal)


        }
    }

    @objc private func viewClicked(_ sender: Any) {
        delegate?.mainViewTapped()
    }


    @objc private func playerDidFinishPlaying() {
        playBtn.setImage(#imageLiteral(resourceName: "play_circle"), for: .normal)
        delegate?.didStatusChange(status: .finished)
        //reset after finishing
        player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
    }

    func stopVideo() {
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
    private func pauseVideo() {
        player?.pause()
        playBtn.setImage(#imageLiteral(resourceName: "play_circle"), for: .normal)
        delegate?.didStatusChange(status: .paused)
    }

    private func startPlaying() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player?.play()
            videoImage.isHidden = true
            playBtn.setImage(#imageLiteral(resourceName: "pause_circle"), for: .normal)
            delegate?.didStatusChange(status: .playing)
        } catch let error as NSError {
            
        }

    }

    private func playVideo() {

        let videoURL = URL(fileURLWithPath: currentVideoPath)
        player = AVPlayer(url: videoURL)

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = bounds
        layer.insertSublayer(playerLayer, at: 0)

        startPlaying()


        //track player progress
        let duration = player?.currentItem?.asset.duration

        let interval = CMTime(value: 1, timescale: 2)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (progressTime) in

            self.delegate?.didUpdate(currentProgress: progressTime, duration: duration)



        })

    }
}
