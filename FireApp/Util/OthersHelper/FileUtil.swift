//
// Created by Devlomi on 2019-07-17.
// Copyright (c) 2019 Devlomi. All rights reserved.
//

import Foundation

class FileUtil {
     static func sizeForLocalFilePath(filePath: String) -> UInt64 {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
            if let fileSize = fileAttributes[FileAttributeKey.size] {
                return (fileSize as! NSNumber).uint64Value
            } else {
                
            }
        } catch {
            
        }
        return 0
    }

     static func covertToFileString(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }

    public static func getFileSize(filePath: String) -> String {
        let sizeInt = sizeForLocalFilePath(filePath: filePath)
        return covertToFileString(with: sizeInt)
    }
    public static func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            
        } catch (let error) {
            
            return false
        }
        return true
    }
    
    
    public static func moveItem(at srcURL: URL, to dstURL: URL) -> Bool {
         do {
            
             try FileManager.default.moveItem(at: srcURL, to: dstURL)
             
         } catch (let error) {
             
             return false
         }
         return true
     }
    
    public static func exists( at path:String) ->Bool{
        return FileManager.default.fileExists(atPath: path)
    }
}
