//
//  SentAudioCell.swift
//  FireApp
//
//  Created by Devlomi on 11/23/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class SentAudioCell: SentBaseCell, AudioBase {


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



    override func bind(message: Message,user:User) {
        super.bind(message: message,user:user)

        currentDuration.text = message.mediaDuration
        btnPlay.addTarget(self, action: #selector(playClicked(_:)), for: .touchUpInside)
        durationSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)

        btnPlay.isHidden = message.downloadUploadState != .SUCCESS

    }


    @objc private func handleSliderChange() {
        delegate?.didSeek(indexPath: indexPath, to: durationSlider.value)
    }

    @objc private func playClicked(_ sender: Any) {
        delegate?.didClickPlayButton(indexPath: indexPath, currentProgress: durationSlider.value)
    }





    func updateSlider(currentProgress: TimeInterval, duration: TimeInterval, currentDurationStr: String? = nil) {
        let durationText = currentDurationStr ?? currentProgress.timeFormat()

        currentDuration.text = durationText
        let newSliderValue = Float(currentProgress / duration)
        durationSlider.value = newSliderValue
    }






}
