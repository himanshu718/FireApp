//
//  RingtonesVC.swift
//  FireApp
//
//  Created by Devlomi on 11/17/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import AVFoundation

class RingtonesVC: BaseTableVC {
    var selectedItem: IndexPath!

    let ringtonesDict = Ringtones.ringtones
    var ringtonesArray: [String]!

    var audioPlayer: AudioPlayer?

    var objPlayer: AVAudioPlayer?


    override func viewDidLoad() {
        super.viewDidLoad()


        //get ringtones names
        ringtonesArray = Array(ringtonesDict.keys).sorted()
        let currentRingtone = UserDefaultsManager.getRingtoneName()

        
        let index = ringtonesArray.firstIndex(of: ringtonesArray.filter { $0 == currentRingtone }.first!)!
        //select current saved ringtone
        selectedItem = IndexPath(row: index, section: 0)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))



    }

    //save new selected ringtone
    @objc private func doneTapped() {
        let ringtoneName = ringtonesArray[selectedItem.row]
        let fileName = ringtonesDict[ringtoneName]!
        UserDefaultsManager.setRingtione(ringtoneName: ringtoneName, fileName: fileName)
        navigationController?.popViewController(animated: true)

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ringtoneCell")!
        cell.textLabel?.text = ringtonesArray[indexPath.row]

        //check the ringtone if selected
        cell.accessoryType = indexPath == selectedItem ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ringtonesArray.count
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = indexPath
        tableView.reloadData()

        let ringtoneName = ringtonesArray[indexPath.row]
        let ringtone = ringtonesDict[ringtoneName]!
        
        let url = URL(string: ringtone)!
        let ext = url.pathExtension
        let fileName = url.deletingPathExtension().absoluteString
        
        playAudioFile(fileName: fileName, fileExtension: ext)
    }


    //play ringtone when user selects
    func playAudioFile(fileName:String,fileExtension:String) {



        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            // For iOS 11
            objPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            objPlayer?.numberOfLoops = -1


            guard let aPlayer = objPlayer else { return }
            aPlayer.play()

        } catch let error {

        }


    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        objPlayer?.stop()
    }


}





