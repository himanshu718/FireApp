//
//  FoundationExtensions.swift
//  FireApp
//
//  Created by Devlomi on 12/13/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import UIKit
import WXImageCompress
import Kingfisher
import RealmSwift

extension Int {
    func toDate() -> Date {
        let time = Double(self) / 1000.0
        return Date(timeIntervalSince1970: time)
    }
}

extension URL {
    func deleteFile() throws {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: self)
    }

    func deleteFileNotThrows() {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: self)
        } catch let error {

        }

    }



    func createFolder(folderName: String) -> URL? {
        let fileManager = FileManager.default
        // Get document directory for device, this should succeed
        if let documentDirectory = fileManager.urls(for: .documentDirectory,
            in: .userDomainMask).first {
            // Construct a URL with desired folder name
            let folderURL = documentDirectory.appendingPathComponent(folderName)
            // If folder URL does not exist, create it
            if !fileManager.fileExists(atPath: folderURL.path) {
                do {
                    // Attempt to create folder
                    try fileManager.createDirectory(atPath: folderURL.path,
                        withIntermediateDirectories: true,
                        attributes: nil)
                } catch {
                    // Creation failed. Print error & return nil
                    return nil
                }
            }
            // Folder either exists, or was created. Return URL
            return folderURL
        }
        // Will only be called if document directory not found
        return nil
    }

    func createFolderIfNotExists(folderName: String) -> URL? {
        let fileManager = FileManager.default
        // Get document directory for device, this should succeed
        let dir = self
        let folderURL = dir.appendingPathComponent(folderName)
        // If folder URL does not exist, create it
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                // Attempt to create folder
                try fileManager.createDirectory(atPath: folderURL.path,
                    withIntermediateDirectories: true,
                    attributes: nil)
            } catch {
                // Creation failed. Print error & return nil
                return nil
            }
        }
        // Folder either exists, or was created. Return URL
        return folderURL


    }
}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }

    func currentTimeMillisLong() -> CLong {
        return CLong(self.timeIntervalSince1970 * 1000)
    }

    func currentTimeMillisStr() -> String {
        return String(currentTimeMillis())
    }
}

extension Data {
    func toUIImage() -> UIImage? {
        return UIImage(data: self)
    }

    var imageExtension: String {
        var values = [UInt8](repeating: 0, count: 1)
        self.copyBytes(to: &values, count: 1)

        let ext: String
        switch (values[0]) {
        case 0xFF:
            ext = "jpg"
        case 0x89:
            ext = "png"
        case 0x47:
            ext = "gif"
        case 0x49, 0x4D:
            ext = "tiff"
        default:
            ext = "png"
        }
        return ext
    }


}
extension String {


    func getSymbol() -> String? {
        let locale = NSLocale(localeIdentifier: self)
        if locale.displayName(forKey: .currencySymbol, value: self) == self {
            let newlocale = NSLocale(localeIdentifier: self.dropLast() + "_en")
            return newlocale.displayName(forKey: .currencySymbol, value: self)
        }
        return locale.displayName(forKey: .currencySymbol, value: self)
    }
    
    var localizedStr: String {
        return NSLocalizedString(self, comment: "")
    }



    func toUIColor() -> UIColor {
        var cString: String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }


    func toUIImage() -> UIImage {
        guard let imageData = Data(base64Encoded: self, options: Data.Base64DecodingOptions.ignoreUnknownCharacters), let image = UIImage(data: imageData) else {
            return UIImage()
        }

        return image
    }



 

    func toDate() -> Date {
        let time = Double(self)! / 1000.0
        return Date(timeIntervalSince1970: time)
    }

    func fileName() -> String {
        return NSURL(fileURLWithPath: self).lastPathComponent ?? ""
    }

    func fileExtension() -> String {
        return NSURL(fileURLWithPath: self).pathExtension ?? ""
    }

    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }



}


public extension NSRange {
    private init(string: String, lowerBound: String.Index, upperBound: String.Index) {
        let utf16 = string.utf16

        let lowerBound = lowerBound.samePosition(in: utf16)
        let location = utf16.distance(from: utf16.startIndex, to: lowerBound!)
        let length = utf16.distance(from: lowerBound!, to: upperBound.samePosition(in: utf16)!)

        self.init(location: location, length: length)
    }

    init(range: Range<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }

    init(range: ClosedRange<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
}




extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest = 0
        case low = 0.25
        case medium = 0.5
        case high = 0.75
        case highest = 1
    }

    func toBase64String() -> String {
        let imageData = self.jpegData(compressionQuality: 0)
        return imageData!.base64EncodedString()
    }


    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }




    func toData(_ jpegQuality: JPEGQuality, compress: Bool = false) -> Data? {
//        return self.pngData()!
        let image = compress ? self.wxCompress() : self
        return image.jpegData(compressionQuality: 0.5)
    }

    func toDataPng(compress: Bool = false) -> Data? {
        let image = compress ? self.wxCompress() : self
        return image.pngData()
    }

    func toPng() -> UIImage {
        return UIImage(data: self.pngData()!)!
    }


    func blurred(resize: Bool = false, blurValue: Int = 9) -> UIImage {
        var image = self
        if resize {
            image = resizeImage(image: self, newWidth: 100)
        }

        let context = CIContext(options: nil)

//        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let currentFilter = CIFilter(name: "CIBoxBlur")
        let beginImage = CIImage(image: image)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(blurValue, forKey: kCIInputRadiusKey)

        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")

        let output = cropFilter!.outputImage

//        let output = currentFilter!.value(forKey: kCIOutputImageKey) as! CIImage

        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        return processedImage
    }

    func tinted(with tintColor: UIColor) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        tintColor.set()
        UIRectFill(rect)
        draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return tintedImage
    }


    private func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {

        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    func testBlur() -> UIImage? {
        guard let cgImage = self.cgImage,
            let openGLContext = EAGLContext(api: .openGLES3) else {
                return nil
        }

        let context = CIContext(eaglContext: openGLContext)
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(8.0, forKey: "inputRadius")

        let output = filter?.value(forKey: kCIOutputImageKey) as! CIImage
        let cgImageResult = context.createCGImage(output, from: output.extent)

        return UIImage(cgImage: cgImageResult!)
    }


    func toBase64StringPng() -> String {
        let imageData = self.pngData()
        return imageData!.base64EncodedString()
    }


    func circled() -> UIImage {
        return self.kf.image(withRoundRadius: self.size.width / 2, fit: self.size)
    }

    var toProfileImage: UIImage {
        return self.wxCompress().toPng()
    }
    
    var toProfileThumbImage: UIImage {
        return self.resized(to: CGSize(width: 100, height: 100)).wxCompress().toPng()
    }
}
extension DateFormatter {
    convenience init(formatType: String) {
        self.init()
        dateFormat = formatType

    }
}

extension Double {
    func timeFormat(_ oneZero: Bool = true) -> String {
        let ticks = Int(self)
        if oneZero {
            return String(format: "%d:%02d", ticks / 60, ticks % 60)
        }

        return String(format: "%02d:%02d", ticks / 60, ticks % 60)

    }
}
extension Int {
    func timeFormat(_ oneZero: Bool = true) -> String {
        let ticks = Int(self)
        if oneZero {
            return String(format: "%d:%02d", ticks / 60, ticks % 60)
        }

        return String(format: "%02d:%02d", ticks / 60, ticks % 60)

    }
}

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension User {
    func getUserNameByIdForGroups(userId: String) -> String? {
        let user = self
        if user.isGroupBool {
            if let group = user.group {
                if let foundUser = group.users.filter({ $0.uid == userId }).first {
                    return getUserNameOrPhone(user: foundUser)
                }

                if let storedUser = RealmHelper.getInstance(appRealm).getUser(uid: userId) {
                    return getUserNameOrPhone(user: storedUser)
                }
            }
            //if user is not in group or user is not stored in LocalDB we will return nil so we can return the user's phone
            return nil
        }

        return user.userName
    }
    
    func getUserByIdForGroups(userId: String) -> User? {
          let user = self
          if user.isGroupBool {
              if let group = user.group {
                  if let foundUser = group.users.filter({ $0.uid == userId }).first {
                      return foundUser
                  }

                  if let storedUser = RealmHelper.getInstance(appRealm).getUser(uid: userId) {
                      return storedUser
                  }
              }
              //if user is not in group or user is not stored in LocalDB we will return nil so we can return the user's phone
          }
        
        return RealmHelper.getInstance(appRealm).getUser(uid: userId)


      }

    //return Phone number if user name is not exist
    //since a user maybe removed from a group
    private func getUserNameOrPhone(user: User) -> String {
        if (user.userName == "") {
            return user.phone
        }

        return user.userName
    }

    static func toDict(userList: [User], addCurrentUser: Bool) -> Dictionary<String, Any> {
        var dict = [String: Any]()
        for user in userList {
            dict[user.uid] = false
        }

        if (addCurrentUser) {
            dict[FireManager.getUid()] = true
        }

        return dict
    }

}
extension Realm {
    public func safeWrite(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}

extension URL {
    var isDirectory: Bool {
       return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

@objc extension Object {

    public func detached() -> Self {
        let detached = type(of: self).init()
        for property in objectSchema.properties {
            guard let value = value(forKey: property.name) else { continue }
            if let detachable = value as? Object {
                detached.setValue(detachable.detached(), forKey: property.name)
            } else if let list = value as? RealmListDetachable {
                detached.setValue(list.detached(), forKey: property.name)
            } else {
                detached.setValue(value, forKey: property.name)
            }
        }
        return detached
    }
}

protocol RealmListDetachable {

func detached() -> Self
}
