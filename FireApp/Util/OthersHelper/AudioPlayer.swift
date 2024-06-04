//
//  AudioPlayer.swift
//  FireApp
//
//  Created by Devlomi on 8/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import AVFoundation

protocol AudioPlayerDelegate {
    func didUpdate(currentProgress: TimeInterval, duration: TimeInterval, messageId: String)
    func didFinish(messageId: String)
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    let audioSession = AVAudioSession.sharedInstance()

    var timer: Timer?
    var player: AVAudioPlayer?
    var delegate: AudioPlayerDelegate?
    var messageId = ""

    var speakerType:SpeakerType = .speaker{
        didSet{
            if speakerType == .speaker{
                configureAudioSessionToSpeaker()
            }else if speakerType == .earpiece{
                configureAudioSessionToEarSpeaker()
            }
        }
    }

    init(url: URL, messageId: String, speakerType: SpeakerType) {
        super.init()
        
        do {
            configureAudioSessionCategory()
            if speakerType == .earpiece {
                configureAudioSessionToEarSpeaker()
            } else {
                configureAudioSessionToSpeaker()
            }

            try player = AVAudioPlayer(contentsOf: url)
            player?.volume = 1.0
            player?.delegate = self
            self.messageId = messageId
        } catch let error {

        }

    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        timer?.invalidate()
        delegate?.didFinish(messageId: messageId)
    }

    func play() {
        player?.prepareToPlay()
        player?.play()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { _ in
            self.delegate?.didUpdate(currentProgress: self.player?.currentTime ?? 0, duration: self.player?.duration ?? 0, messageId: self.messageId)
        })


    }

    func pause() {
        player?.pause()
        timer?.invalidate()
    }

    func isPlaying() -> Bool {
        return player?.isPlaying ?? false
    }

    func seek(to: TimeInterval) {
        if let duration = player?.duration {
            let cmTime = CMTime(seconds: duration, preferredTimescale: 1000000)
            let totalSeconds = CMTimeGetSeconds(cmTime)
            let value = Float64(to) * totalSeconds
            player?.currentTime = value

        }
    }

    private func configureAudioSessionCategory() {
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.voiceChat)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
           
        } catch (let error) {
        }
    }

    private func configureAudioSessionToSpeaker() {
        do {
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try audioSession.setActive(true)
        } catch let error as NSError {
        }
    }

    private func configureAudioSessionToEarSpeaker() {

        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do { ///Audio Session: Set on Speaker
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            try audioSession.setActive(true)

        }
        catch {
        }
    }


}

enum SpeakerType {
    case earpiece
    case speaker
}
