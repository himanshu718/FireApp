//
// Created by Devlomi on 2019-07-16.
// Copyright (c) 2019 Devlomi. All rights reserved.
//

import Foundation

struct FilesExtensions {
    static let EXTENSION_JPG = "jpg";
    static let EXTENSION_MP4 = "mp4";
    static let EXTENSION_WAV = "m4a";
    static let APP_FOLDER_NAME = Config.appName
    static let groupName = "group.\(Config.bundleName)"
}

class DirManager {

    class func fileManager() -> FileManager {
        return FileManager.default

    }

    class func documentsDirectory() -> URL {
        return fileManager().containerURL(forSecurityApplicationGroupIdentifier: Config.groupName)!
    }

    class func getSentImageFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Images/Sent")!
    }

    class func getReceivedImageFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Images")!
    }

    class func getSentVideoFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Videos/Sent")!
    }

    class func getReceivedVideoFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Videos")!
    }

    class func getSentVoiceFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "VoiceMessages/Sent")!
    }

    class func getReceivedVoiceFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "VoiceMessages")!
    }


    class func getSentAudioFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Audio/Sent")!
    }

    class func getReceivedAudioFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Audio")!
    }

    class func getReceivedStatusFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Statuses")!
    }


    class func getReceivedFileFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Files/Sent")!
    }


    class func getSentFileFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Files")!
    }


    class func getUserProfileImagesFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Profile Photos")!
    }

    class func generateUserProfileImage() -> URL {
        let name = UUID().uuidString
        return getUserProfileImagesFolder().appendingPathComponent(name).appendingPathExtension(FilesExtensions.EXTENSION_JPG)
    }
    
    class func getSentStickersFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Stickers/Sent")!
    }

    class func getReceivedStickersFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Stickers")!
    }
    
    class func getBackupFolder() -> URL {
        return documentsDirectory().createFolderIfNotExists(folderName: FilesExtensions.APP_FOLDER_NAME  + "Backup")!
    }


    //get file type for the file name
    private class func getFileTypeString(type: MessageType) -> String {
        switch (type) {
        case MessageType.SENT_IMAGE, MessageType.RECEIVED_IMAGE:
            return "IMG";


        case MessageType.SENT_VIDEO, MessageType.RECEIVED_VIDEO:
            return "VID";


        case MessageType.SENT_AUDIO, MessageType.RECEIVED_AUDIO:
            return "AUD";


        case MessageType.SENT_VOICE_MESSAGE, MessageType.RECEIVED_VOICE_MESSAGE:
            //push to talk (voice message)
            return "PTT";
            
            
        case .SENT_STICKER,.RECEIVED_STICKER:
            return "STI"


        default:
            return "FILE";


        }

    }

    private class func generateNewName(type: MessageType) -> String {
        let dateFormatterGet = DateFormatter()

        dateFormatterGet.dateFormat = "yyyyMMddSSSS"
        //the Locale us is to use english numbers
        dateFormatterGet.locale = Locale(identifier: "US")


        let stringDate = dateFormatterGet.string(from: Date())


        return getFileTypeString(type: type) + "-" + stringDate
    }

    public class func getFileExtensionByType(_ type: MessageType) -> String {

        switch type {
        case .SENT_IMAGE, .RECEIVED_IMAGE:
            return FilesExtensions.EXTENSION_JPG



        case .SENT_VIDEO, .RECEIVED_VIDEO:
            return FilesExtensions.EXTENSION_MP4

        case .SENT_VOICE_MESSAGE, .RECEIVED_VOICE_MESSAGE:
            return FilesExtensions.EXTENSION_WAV


        case .SENT_AUDIO, .RECEIVED_AUDIO:
            return FilesExtensions.EXTENSION_WAV
        
        default:
            return FilesExtensions.EXTENSION_JPG

        }
    }

    public class func generateFile(type: MessageType, fileExtension: String = "") -> URL {

        let name = generateNewName(type: type)
        var mExtension = fileExtension

        if mExtension == "" {
            mExtension = getFileExtensionByType(type)
        }


        switch type {
        case .SENT_IMAGE:
            return getSentImageFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .RECEIVED_IMAGE:
            return getReceivedImageFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .SENT_VIDEO:
            return getSentVideoFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .RECEIVED_VIDEO:
            return getReceivedVideoFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .SENT_VOICE_MESSAGE:
            return getSentVoiceFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .RECEIVED_VOICE_MESSAGE:
            return getReceivedVoiceFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .SENT_AUDIO:
            return getSentAudioFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .RECEIVED_AUDIO:
            return getReceivedAudioFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .SENT_FILE:
            return getSentFileFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        case .SENT_STICKER:
            return getSentStickersFolder().appendingPathComponent(name).appendingPathExtension(mExtension)
            
        case .RECEIVED_STICKER:
            return getReceivedStickersFolder().appendingPathComponent(name).appendingPathExtension(mExtension)

        default:
            return getReceivedFileFolder().appendingPathComponent(name).appendingPathExtension(mExtension)
        }

    }

    public class func getReceivedStatusFile(statusId: String, statusType: StatusType) -> URL {
   
        if statusType == .video {
            return DirManager.getReceivedStatusFolder().appendingPathComponent(statusId).appendingPathExtension("mp4")
        }

        return DirManager.getReceivedStatusFolder().appendingPathComponent(statusId).appendingPathExtension("jpg")
    }






}





