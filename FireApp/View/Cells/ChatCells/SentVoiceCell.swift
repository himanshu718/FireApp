//
//  SentVoiceCell.swift
//  FireApp
//
//  Created by Devlomi on 8/23/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import AVKit

enum PlayerState {
    case playing, paused
}




class SentVoiceCell: SentBaseCell, AudioBase {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var micStateImage: UIImageView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var currentDuration: UILabel!

    var playerState: PlayerState = .paused {
        didSet {
            if playerState == .playing {
                btnPlay.setImage(UIImage(named: "pause"), for: .normal)
            } else {
                btnPlay.setImage(UIImage(named: "play_arrow"), for: .normal)
            }
        }
    }

    var delegate: AudioCellDelegate?




     func bind(message: Message,user:User,userImage:UIImage) {
        super.bind(message: message,user:user)
        currentDuration.text = message.mediaDuration
        btnPlay.addTarget(self, action: #selector(playClicked(_:)), for: .touchUpInside)
        durationSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        micStateImage.image = MessageTypeHelper.getColoredImage(message: message)
        btnPlay.isHidden = message.downloadUploadState != .SUCCESS
        userImageView.image = userImage

    }


    @objc private func handleSliderChange() {
        delegate?.didSeek(indexPath: indexPath, to: durationSlider.value)
    }

    @objc private func playClicked(_ sender: Any) {
        delegate?.didClickPlayButton(indexPath: indexPath, currentProgress: durationSlider.value)
    }





    func updateSlider(currentProgress: TimeInterval, duration: TimeInterval, currentDurationStr: String?) {
        let durationText = currentDurationStr ?? currentProgress.timeFormat()

        currentDuration.text = durationText
        let newSliderValue = Float(currentProgress / duration)
        durationSlider.value = newSliderValue
    }

}

