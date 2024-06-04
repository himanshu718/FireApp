//
//  BackupChatCell.swift
//  FireApp
//
//  Created by Devlomi on 3/24/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit

class BackupChatCell: UITableViewCell {
    @IBOutlet weak var typeLbl:UILabel!
    @IBOutlet weak var sizeLbl:UILabel!
    @IBOutlet weak var selectedSwitch:UISwitch!
    
    private var mediaItem:MediaTypeBackupData!
    private var index:Int!
    
    weak var delegate:BackupChatCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //resize uiswitch
        selectedSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        selectedSwitch.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)

    }

    @objc private func switchChanged(_ sender: UISwitch){
        delegate?.didToggleSwitch(item: mediaItem, index: index, isOn: sender.isOn)
    }

    func bind(mediaItem:MediaTypeBackupData,index:Int){
        self.mediaItem = mediaItem
        self.index = index
        typeLbl.text = getMediaNameByType(messageType: mediaItem.type)
        sizeLbl.text = FileUtil.covertToFileString(with:UInt64(mediaItem.size))        
    }
    
    
    private func getMediaNameByType(messageType:MessageType) -> String{
        switch messageType {
        case .SENT_IMAGE:
            return Strings.sent_images
        case .RECEIVED_IMAGE:
            return Strings.received_images
            
        case .SENT_VIDEO:
            return Strings.sent_videos
        case .RECEIVED_VIDEO:
            return Strings.received_videos
            
        case .SENT_VOICE_MESSAGE:
            return Strings.sent_voice_messages
            
        case .RECEIVED_VOICE_MESSAGE:
            return Strings.received_voice_messages
            
        case .SENT_STICKER:
            return Strings.sent_stickers
            
        case .RECEIVED_STICKER:
            return Strings.received_stickers
            
        default:
            return Strings.others
        }
    }

}
protocol BackupChatCellDelegate:class {
    func didToggleSwitch(item:MediaTypeBackupData,index:Int,isOn:Bool)
}
