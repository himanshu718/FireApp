//
//  PreviewScheduledMessageVC.swift
//  FireApp
//
//  Created by Devlomi on 4/23/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import BottomPopup
import RealmSwift

class PreviewScheduledMessageVC: BottomPopupViewController {

    @IBOutlet weak var tableView:UITableView!
    
    
    private var scheduledMessageId = ""
    private var scheduledMessages:Results<ScheduledMessage>!
    private var senderUser:User!
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        senderUser = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        scheduledMessages = appRealm.objects(ScheduledMessage.self).filter("\(DBConstants.MESSAGE_ID) == '\(scheduledMessageId)'")
        registerCells()
        
    }
    

 
    //registering TableViewCells
       private func registerCells() {
           tableView.registerCellNib(cellClass: SentTextCell.self)
           tableView.registerCellNib(cellClass: SentTextQuotedCell.self)
           tableView.registerCellNib(cellClass: ReceivedTextCell.self)
           tableView.registerCellNib(cellClass: SentImageCell.self)
           tableView.registerCellNib(cellClass: SentVideoCell.self)
           tableView.registerCellNib(cellClass: SentVoiceCell.self)
           tableView.registerCellNib(cellClass: SentAudioCell.self)
           tableView.registerCellNib(cellClass: SentContactCell.self)
           tableView.registerCellNib(cellClass: SentLocationCell.self)
           tableView.registerCellNib(cellClass: SentFileCell.self)
           tableView.registerCellNib(cellClass: SentFileQuotedCell.self)


           tableView.registerCellNib(cellClass: ReceivedImageCell.self)
           tableView.registerCellNib(cellClass: ReceivedVoiceCell.self)
           tableView.registerCellNib(cellClass: ReceivedContactCell.self)
           tableView.registerCellNib(cellClass: ReceivedContactQuotedCell.self)
           tableView.registerCellNib(cellClass: ReceivedVideoCell.self)
           tableView.registerCellNib(cellClass: ReceivedLocationCell.self)
           tableView.registerCellNib(cellClass: ReceivedAudioCell.self)
           tableView.registerCellNib(cellClass: ReceivedFileCell.self)

           tableView.registerCellNib(cellClass: GroupEventCell.self)
           tableView.registerCellNib(cellClass: DateHeaderCell.self)

           tableView.registerCellNib(cellClass: SentDeletedMessageCell.self)
           tableView.registerCellNib(cellClass: ReceivedDeletedMessageCell.self)

           tableView.registerCellNib(cellClass: UnSupportedCell.self)


       }
}

extension PreviewScheduledMessageVC:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduledMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let scheduledMessage = scheduledMessages[indexPath.row]
        
        let tempUser = User()
        tempUser.uid = scheduledMessage.toId
        
        let user = RealmHelper.getInstance(appRealm).getUser(uid: scheduledMessage.toId) ?? tempUser
        
        let message = scheduledMessage.toMessage()

          switch message.typeEnum {
          case .RECEIVED_TEXT:
              let cell = tableView.dequeue() as ReceivedTextCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .SENT_IMAGE:
              let cell = tableView.dequeue() as SentImageCell
              cell.bind(message: message, user: user)
              initCell(cell: cell, indexPath: indexPath)

              cell.imageContent.hero.id = message.messageId
              cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
              cell.imageContent.isOpaque = true
              return cell

          case .SENT_TEXT:
              var cell: BaseCell!
              if message.quotedMessage == nil {
                  cell = tableView.dequeue() as SentTextCell
              } else {
                  cell = tableView.dequeue() as SentTextQuotedCell
              }

              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .SENT_VIDEO:
              let cell = tableView.dequeue() as SentVideoCell
              cell.hero.id = message.messageId
              cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell


          case .SENT_VOICE_MESSAGE:
              let cell = tableView.dequeue() as SentVoiceCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user, userImage: senderUser.thumbImg.toUIImage())
              return cell

          case .RECEIVED_AUDIO:
              let cell = tableView.dequeue() as ReceivedAudioCell
              initCell(cell: cell, indexPath: indexPath)

              cell.bind(message: message, user: user)
              return cell

          case .SENT_CONTACT:
              let cell = tableView.dequeue() as SentContactCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .SENT_LOCATION:
              let cell = tableView.dequeue() as SentLocationCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .SENT_FILE:
              var cell: BaseCell!
              if message.quotedMessage == nil {
                  cell = tableView.dequeue() as SentFileCell
              } else {
                  cell = tableView.dequeue() as SentFileQuotedCell
              }

              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .GROUP_EVENT:
              let cell = tableView.dequeue() as GroupEventCell

              if let group = user.group {
                  let text = GroupEvent.extractString(messageContent: message.content, users: group.users)
                  cell.bind(text: text)
              }

              return cell

          case .DATE_HEADER:
              let cell = tableView.dequeue() as DateHeaderCell

              cell.bind(message: message)

              return cell

          case .RECEIVED_IMAGE:
              let cell = tableView.dequeue() as ReceivedImageCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              cell.imageContent.hero.id = message.messageId
              cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
              cell.imageContent.isOpaque = true
              return cell


          case .RECEIVED_VOICE_MESSAGE:
              let cell = tableView.dequeue() as ReceivedVoiceCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell


          case .RECEIVED_CONTACT:
              var cell: ReceivedContactCell!
              if message.quotedMessage == nil {
                  cell = tableView.dequeue() as ReceivedContactCell
              } else {
                  cell = tableView.dequeue() as ReceivedContactQuotedCell
              }

              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .RECEIVED_VIDEO:
              let cell = tableView.dequeue() as ReceivedVideoCell
              cell.hero.id = message.messageId
              cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell


          case .RECEIVED_LOCATION:
              let cell = tableView.dequeue() as ReceivedLocationCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell


          case .SENT_AUDIO:
              let cell = tableView.dequeue() as SentAudioCell
              initCell(cell: cell, indexPath: indexPath)

              cell.bind(message: message, user: user)
              return cell

          case .RECEIVED_FILE:
              let cell = tableView.dequeue() as ReceivedFileCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .SENT_DELETED_MESSAGE:
              let cell = tableView.dequeue() as SentDeletedMessageCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          case .RECEIVED_DELETED_MESSAGE:
              let cell = tableView.dequeue() as ReceivedDeletedMessageCell
              initCell(cell: cell, indexPath: indexPath)
              cell.bind(message: message, user: user)
              return cell

          default:
              let cell = tableView.dequeue() as UnSupportedCell
              cell.bind(message: message, user: user)
              return cell

          }

      }
    
    private func initCell(cell: BaseCell, indexPath: IndexPath) {
           cell.progressButton?.progress = 0

           cell.progressButton?.isHidden = true

      }
    
    func initialize(scheduledMessageId:String) {
        self.scheduledMessageId = scheduledMessageId
    }
    
    
    
}
