//
//  MessageTypeHelper.swift
//  FireApp
//
//  Created by Devlomi on 9/15/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import UIKit

class MessageTypeHelper {

    public static func getMessageTypeImage(type: MessageType) -> String {

        switch (type) {

        case MessageType.SENT_IMAGE, MessageType.RECEIVED_IMAGE:
            return "ic_camera"

        case MessageType.SENT_VIDEO, MessageType.RECEIVED_VIDEO:
            return "video"


        case MessageType.SENT_VOICE_MESSAGE, MessageType.RECEIVED_VOICE_MESSAGE:
            return "mic_black"


        case MessageType.SENT_AUDIO, MessageType.RECEIVED_AUDIO:
            return "audio"

        case MessageType.SENT_CONTACT, MessageType.RECEIVED_CONTACT:
            return "person"

        case MessageType.SENT_LOCATION, MessageType.RECEIVED_LOCATION:
            return "location"

        case MessageType.SENT_FILE, MessageType.RECEIVED_FILE:
            return "file"
            
        case MessageType.SENT_DELETED_MESSAGE,MessageType.RECEIVED_DELETED_MESSAGE:
            return "deleted"

        default:
            return "";
        }

    }

    public static func getTypeText(type: MessageType) -> String {
        switch (type) {
        case MessageType.SENT_IMAGE
             , MessageType.RECEIVED_IMAGE:
            return Strings.photo

        case MessageType.SENT_VIDEO,
             MessageType.RECEIVED_VIDEO:
            return Strings.video


        case MessageType.SENT_VOICE_MESSAGE,
             MessageType.RECEIVED_VOICE_MESSAGE:
            return Strings.voice_message


        case MessageType.SENT_AUDIO,
             MessageType.RECEIVED_AUDIO:
            return Strings.audio


        case MessageType.SENT_FILE
             , MessageType.RECEIVED_FILE:
            return Strings.file


        case MessageType.SENT_LOCATION,
             MessageType.RECEIVED_LOCATION:
            return Strings.location

        case MessageType.SENT_STICKER,
             MessageType.RECEIVED_STICKER:
            return Strings.sticker
            

        default:
            return "";
        }

    }

    public static func extractMessageTypeMetadataText(message: Message) -> String {
        if (message.typeEnum.isVoice()) {
            //set the voice message duration
            return message.mediaDuration

        } else if (message.typeEnum.isContact()) {
            //set contact name
            return message.contact?.name ?? ""
        }
        return getTypeText(type: message.typeEnum)
    }

    //get message content with emoji icon if needed
    public static func getMessageContent(message: Message, includeEmoji: Bool) -> String {
        var contentText = ""
        //if it's a text message we don't need to show an Emoji
        if (message.typeEnum.isText()) {
            contentText = message.content
        }else if message.typeEnum.isDeletedMessage(){
            return Strings.this_message_deleted
        }
            
        else {
            let emojiText = includeEmoji ? getEmojiIcon(type: message.typeEnum) + " " : "";
            
            
            //if it's a voice message add mic icon at the start along with voice message duration in ()
            if (message.typeEnum.isVoice()) {
                contentText = emojiText + getTypeText(type: message.typeEnum) + " (" + message.mediaDuration + ")";
                //if it's a contact message show contact icon + the contact name
            } else if message.typeEnum.isContact(),let contact = message.contact {
                let name = contact.name.isEmpty ? message.content : contact.name
                contentText = emojiText + name + MessageTypeHelper.getTypeText(type: message.typeEnum);
            } else {
                //otherwise get the needed emoji(image,video,file location etc..)
                contentText = emojiText + MessageTypeHelper.getTypeText(type: message.typeEnum);
            }
        }
        return contentText
    }
    static func getColoredImage(message: Message) -> UIImage {
        let imageName = getMessageTypeImage(type: message.typeEnum)
        let image = UIImage(named: imageName) ?? UIImage()
        let type = message.typeEnum
        if type.isVoice() {
            if type == .SENT_VOICE_MESSAGE {
                if message.voiceMessageSeen {
                    return image.tinted(with: Colors.voiceMessageSeenColor)!
                } else {
                    return image.tinted(with: Colors.voiceMessageNotSeenColor)!
                }
            } else {
                if message.voiceMessageSeen {
                    return image.tinted(with: Colors.voiceMessageSeenColor)!

                } else {
                    return image.tinted(with: Colors.voiceMessageNotSeenColor)! 

                }
            }
        } else {
            return image.tinted(with: Colors.chatsListIconColor) ?? UIImage()
        }
    }

    static func getColoredReadTags(state: MessageState) -> UIImage {

        switch state {
        case .PENDING:
            return UIImage(named: "pending")!.tinted(with: Colors.readTagsPendingColor)!
        case .SENT:
            return UIImage(named: "check")!.tinted(with: Colors.readTagsSentColor)!

        case .RECEIVED:
       
            return UIImage(named: "check_read")!.tinted(with: Colors.readTagsReceivedColor)!

        case .READ:
            return UIImage(named: "check_read")!.tinted(with: Colors.readTagsReadColor)!
            
        case .NONE:
            return UIImage()

        }
    }
    
    //this is to show emoji icon at start of the notification
    public static func getEmojiIcon(type:MessageType) ->String {

          switch (type) {

              case MessageType.RECEIVED_IMAGE:
                  return "📷";


              case MessageType.RECEIVED_VIDEO:
                  return "📹";


              case MessageType.RECEIVED_VOICE_MESSAGE:
                  return "🎤";


              case MessageType.RECEIVED_AUDIO:
                  return "🎵";

              case MessageType.RECEIVED_CONTACT:
                  return "👤";

              case MessageType.RECEIVED_LOCATION:
                  return "📍";

              case MessageType.RECEIVED_FILE:
                  return "📁";
                

              default:
                  return "";
          }
      }

}
