//
//  Extensions.swift
//  FireApp
//
//  Created by Devlomi on 6/4/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import RealmSwift
import JFContactsPicker
import Contacts
import LocationPicker
import RxSwift
import AVFoundation
import WXImageCompress
import CoreLocation
import AlertBar

let maxFontSize: CGFloat = 100

extension UITableView {
    func registerCellNib<Cell: UITableViewCell>(cellClass: Cell.Type) {
        self.register(UINib(nibName: String(describing: Cell.self), bundle: nil), forCellReuseIdentifier: String(describing: Cell.self))
    }
    
    func dequeue<Cell: UITableViewCell>() -> Cell {
        let identifier = String(describing: Cell.self)
        
        guard let cell = self.dequeueReusableCell(withIdentifier: identifier) as? Cell else {
            fatalError("Error in cell")
        }
        
        return cell
    }
    
    var lastVisibleRow: Int {
        
        if visibleCells.count == 0 {
            return 0
        }
        
        let lastVisibleCell = self.visibleCells[self.visibleCells.lastIndex()]
        return self.indexPath(for: lastVisibleCell)?.row ?? 0
        
    }
    
}

extension UICollectionView {
    func registerCellNib<Cell: UICollectionViewCell>(cellClass: Cell.Type) {
        self.register(UINib(nibName: String(describing: Cell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: Cell.self))
    }
    
    func registerCell<Cell: UICollectionViewCell>(cellClass: Cell.Type) {
        self.register(cellClass, forCellWithReuseIdentifier: String(describing: Cell.self))
    }
    
    
    func dequeue<Cell: UICollectionViewCell>(indexPath: IndexPath) -> Cell {
        let identifier = String(describing: Cell.self)
        
        
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? Cell else {
            fatalError("Error in cell")
        }
        
        return cell
    }
}

extension Thread {
    
    var threadName: String {
        if let currentOperationQueue = OperationQueue.current?.name {
            return "OperationQueue: \(currentOperationQueue)"
        } else if let underlyingDispatchQueue = OperationQueue.current?.underlyingQueue?.label {
            return "DispatchQueue: \(underlyingDispatchQueue)"
        } else {
            let name = __dispatch_queue_get_label(nil)
            return String(cString: name, encoding: .utf8) ?? Thread.current.description
        }
    }
}

extension UITextView {
    
    func clear() {
        self.text = ""
    }
    
    func highlightText(text: String) {
        
        let range = (text as NSString).range(of: text)
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: Colors.highlightMessageColor, range: range)
        attributedString.addAttribute(NSAttributedString.Key.font, value: self.font!, range: range)
        self.attributedText = attributedString
        
        
    }
    
    func resizeFont() {
        let textView = self
        
        if (textView.text.isEmpty || textView.bounds.size.equalTo(.zero)) {
            return;
        }
        
        let textViewSize = textView.frame.size;
        let fixedWidth = textViewSize.width - 200
        let expectSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        
        var expectFont = textView.font;
        if (expectSize.height > textViewSize.height) {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height && textView.font!.pointSize < maxFontSize) {
                
                let fontSize = textView.font!.pointSize - 1
                
                expectFont = textView.font!.withSize(fontSize)
                textView.font = expectFont
            }
        }
        else {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height && textView.font!.pointSize < maxFontSize) {
                
                
                let fontSize = textView.font!.pointSize + 1
                expectFont = textView.font;
                textView.font = textView.font!.withSize(fontSize)
            }
            textView.font = expectFont;
        }
    }
}



extension CGFloat {
    func fromatSecondsFromTimer() -> String {
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
}





extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        var chars = Array(hexString.hasPrefix("#") ? hexString.dropFirst() : hexString[...])
        let red, green, blue, alpha: CGFloat
        switch chars.count {
        case 3:
            chars = chars.flatMap {
                [$0, $0]
            }
            fallthrough
        case 6:
            chars = ["F", "F"] + chars
            fallthrough
        case 8:
            alpha = CGFloat(strtoul(String(chars[0...1]), nil, 16)) / 255
            red = CGFloat(strtoul(String(chars[2...3]), nil, 16)) / 255
            green = CGFloat(strtoul(String(chars[4...5]), nil, 16)) / 255
            blue = CGFloat(strtoul(String(chars[6...7]), nil, 16)) / 255
        default:
            return nil
        }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}


extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
    
    func wrapInUiView() -> UIView {
        let subView = UIView(frame: bounds)
        
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
        return subView
    }
}
extension UIView {
    func hideOrShow() {
        self.isHidden = !isHidden
    }
    
    func imageWithView() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0)
        defer { UIGraphicsEndImageContext() }
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

extension UINavigationController {
    func popToVc(viewController: AnyClass) {
        for controller in self.viewControllers as Array {
            if controller.isKind(of: viewController.self) {
                self.popToViewController(controller, animated: true)
                break
            }
        }
    }
}

extension Results {
    func getItemSafely(index: Int) -> Object? {
        if self.indices.contains(index) {
            return self[index] as! Object
        }
        return nil
    }
    
    func lastIndex() -> Int {
        if self.count > 0 {
            return self.count - 1
        }
        return 0
    }
}
extension Results where Element: Message {
    func getIndexById(messageId: String) -> Int? {
        let messages = self as! Results<Message>
        let foundMessage = messages.filter({ $0.messageId == messageId }).first
        
        if let message = foundMessage {
            return messages.index(of: message)
        }
        
        return nil
    }
}

extension Results where Element: Chat {
    func getIndexById(chatId: String) -> Int? {
        let chats = self as! Results<Chat>
        let foundChat = chats.filter({ $0.chatId == chatId }).first
        
        if let chat = foundChat {
            return chats.index(of: chat)
        }
        
        return nil
    }
}




extension UIBarButtonItem {
    func hide() {
        self.isEnabled = false
        self.tintColor = .clear
    }
    func show() {
        self.isEnabled = true
        self.tintColor = nil
    }
    
}

extension UIToolbar {
    func findUIButtonItemByTag(tag: Int) -> UIBarButtonItem? {
        guard let items = self.items else {
            return nil
        }
        for item in items {
            if item.tag == tag {
                return item
            }
        }
        return nil
    }
}
extension Contact {
    func toRealmContact() -> RealmContact {
        let name = self.displayName
        let numbers = self.phoneNumbers.map { $0.phoneNumber }
        
        let realmPhoneNumbers = List<PhoneNumber>()
        
        
        for number in numbers {
            let phoneNumber = PhoneNumber()
            phoneNumber.number = number
            realmPhoneNumbers.append(phoneNumber)
        }
        
        let realmContact = RealmContact()
        realmContact.name = name
        realmContact.realmList = realmPhoneNumbers
        return realmContact
        
    }
    
    
}
extension CNContact {
    func toRealmContact() -> RealmContact {
        let name = self.givenName
        let numbers = self.phoneNumbers.map { $0.value.stringValue }
        
        let realmPhoneNumbers = List<PhoneNumber>()
        
        
        for number in numbers {
            let phoneNumber = PhoneNumber()
            phoneNumber.number = number
            realmPhoneNumbers.append(phoneNumber)
        }
        
        let realmContact = RealmContact()
        realmContact.name = name
        realmContact.realmList = realmPhoneNumbers
        return realmContact
    }
    
    func convertToVcfAndGetFile() -> URL? {
        let fileManager = FileManager.default
        let cacheDirectory = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let fileLocation = cacheDirectory.appendingPathComponent("\(CNContactFormatter().string(from: self)!).vcf")
        
        let contactData = try! CNContactVCardSerialization.data(with: [self])
        do {
            try contactData.write(to: fileLocation, options: .atomicWrite)
            return fileLocation
        } catch {
            return nil
        }
        
        
    }
}



extension RealmContact {
    func toCNContact() -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = self.name
        var numbers = [CNLabeledValue<CNPhoneNumber>]()
        
        for number in self.realmList {
            let cnNumber = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: number.number))
            numbers.append(cnNumber)
        }
        
        contact.phoneNumbers = numbers
        return contact
    }
    
}


extension Location {
    func toRealmLocation() -> RealmLocation {
        
        let realmLocation = RealmLocation()
        
        let name = self.name ?? self.title ?? ""
        let lat = self.coordinate.latitude
        let lng = self.coordinate.longitude
        
        realmLocation.name = name
        
        
        
        realmLocation.lat = lat
        realmLocation.lng = lng
        
        
        return realmLocation
    }
}

extension RealmCollectionChange {
    func updateTableView(tableView: UITableView, section: Int = 0, noAnimationsOnUpdate: Bool = false) {
        switch self {
        case .initial:
            // Results are now populated and can be accessed without blocking the UI
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            // Query results have changed, so apply them to the UITableView
            tableView.beginUpdates()
            
            tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: section) }),
                                 with: .automatic)
            tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: section) }),
                                 with: .automatic)
            
            //            if noAnimationsOnUpdate {
            //                UIView.setAnimationsEnabled(false)
            //
            //                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: section) }),
            //                    with: .none)
            //
            //                UIView.setAnimationsEnabled(true)
            //                UIView.performWithoutAnimation {
            //                    let loc = tableView.contentOffset
            //                     tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: section) }),
            //                                        with: .none)
            //                        tableView.contentOffset = loc
            //                }
            //            } else {
            tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: section) }),
                                 with: .automatic)
            
            //            }
            
            tableView.endUpdates()
        case .error(let error):
            // An error occurred while opening the Realm file on the background worker thread
            fatalError("\(error)")
        }
        
    }
}

extension Observable {
    func unique(source: Observable<String>) -> Observable<String> {
        var cache = Set<String>()
        
        return source.flatMap { element -> Observable<String> in
            if cache.contains(element) {
                return Observable<String>.empty()
            } else {
                cache.insert(element)
                return Observable<String>.just(element)
            }
        }
    }
}


extension UIDevice {
    
    class var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    class var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    class var isTV: Bool {
        return UIDevice.current.userInterfaceIdiom == .tv
    }
    
    class var isCarPlay: Bool {
        return UIDevice.current.userInterfaceIdiom == .carPlay
    }
    
}

extension UIViewController {
    
    func showAlert(type: AlertBarType, message: String) {
        
        AlertBar.show(type: type, message: message, options: .init(isStretchable: true, textAlignment: .center))
    }
    
    func loadingAlert() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: Strings.please_wait, preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        return alert
    }
    
    func hideStatusBar() {
        if #available(iOS 13.0, *) {
            
        } else {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = true
        }
    }
    
    func properAlert(title:String?,message:String?,preferredStyle:UIAlertController.Style) -> UIAlertController{
        let style:UIAlertController.Style = UIDevice.isPhone ? preferredStyle : .alert
        return UIAlertController(title: title, message: message, preferredStyle: style)
    }
    
    func presentAlertWith(title: String, message: String, options: String..., completion: @escaping (Int) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for (index, option) in options.enumerated() {
            alertController.addAction(UIAlertAction.init(title: option, style: .default, handler: { (action) in
                completion(index)
            }))
        }
        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIFont {
    //get the actual font name not by providing font name
    static func getFontByFileName(_ fontNameWithExtension: String) -> UIFont {
        
        var fontName = fontNameWithExtension
        
        if fontName.contains(".ttf") {
            fontName = fontName.replacingOccurrences(of: ".ttf", with: "")
        }
        
        
        for family: String in UIFont.familyNames {
            
            for names: String in UIFont.fontNames(forFamilyName: family) {
                
                if fontName == names {
                    return UIFont(name: family, size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                }
            }
        }
        
        return UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
}

extension Array {
    func lastIndex() -> Int {
        if self.count > 0 {
            return self.count - 1
        }
        
        return 0
        
    }
    
    func randomIndex() -> Int {
        return Int.random(in: 0..<self.lastIndex())
    }
}

extension UIViewController {
    func distnictTwoArrays(_ array1: [String], _ array2: [String]) -> [String] {
        var union = array1 + array2
        var intersection = [String]()
        intersection.append(contentsOf: array1)
        intersection = Array(Set(array1).intersection(Set(array2)))
        union.removeAll { intersection.contains($0) }
       return union
    }
}

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        
        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}

extension RealmLocation {
    func toShareableURL() -> String {
        let mapsUrl = "https://maps.google.com/?q=\(self.lat),\(self.lng)"
        return "\(self.name) \n \(mapsUrl)"
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

extension UIAlertController {
    func addImage(image: UIImage) {
        
        let maxSize = CGSize(width: 240, height: 244)
        let imgSize = image.size
        var ratio:CGFloat!
        if (imgSize.width > imgSize.height){
            ratio = maxSize.width / imgSize.width
        }else {
            ratio = maxSize.height / imgSize.height
        }
        let scaleSize = CGSize(width: imgSize.width*ratio, height: imgSize.height*ratio)
        var resizedImage = image.imageWithSize(scaleSize)
        
        if (imgSize.height > imgSize.width) {
            let left = (maxSize.width - resizedImage.size.width) / 2
            resizedImage = resizedImage.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -left, bottom: 0, right: 0))
        }
        
        let imgAction = UIAlertAction(title: "", style: .default, handler: nil)
        imgAction.isEnabled = false
        imgAction.setValue(resizedImage.withRenderingMode(.alwaysOriginal), forKey: "image")
        
        self.addAction(imgAction)
    }
}

extension UIImage {
    
    func imageWithSize(_ size:CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        self.draw(in: scaledImageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}
