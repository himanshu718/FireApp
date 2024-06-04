//
//  AudioRecorder.swift
//  FireApp
//
//  Created by Devlomi on 8/23/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioSession: AVAudioSession!
    var url: URL!
    private var soundRecorder: AVAudioRecorder?


    let recordSettings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

//    let recordSettings = [AVFormatIDKey: Int(kAudioFormatOpus),
//                          //                              AVAudioFileTypeKey: kAudioFileWAVEType,
//        AVEncoderAudioQualityKey:AVAudioQuality.medium.rawValue,
////        AVEncoderBitRateKey:320000,
//        AVNumberOfChannelsKey: 1,
//        AVSampleRateKey: 12000
//        ] as [String : Any]


    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    }
    private func setupRecorder() {

        url = DirManager.generateFile(type: .SENT_VOICE_MESSAGE)
        
        do {

            try soundRecorder = AVAudioRecorder(url: url, settings: recordSettings)

            soundRecorder?.delegate = self
            soundRecorder?.prepareToRecord()
            audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat)
            try audioSession.setActive(true)

            if soundRecorder == nil {
                audioSession.requestRecordPermission { (bool: Bool) in }
            }
        } catch let error {

        }


    }
    func start() {
        setupRecorder()
        soundRecorder?.record()
    }

    func stop() {
        soundRecorder?.stop()
    }

    func releaseAudioRecorder() {
        stop()
        soundRecorder = nil
        do {
            try audioSession.setActive(false)
        } catch let error {

        }
    }
}
