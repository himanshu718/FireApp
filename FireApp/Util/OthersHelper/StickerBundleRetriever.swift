//
//  StickerBundleRetriever.swift
//  FireApp
//
//  Created by Devlomi on 3/15/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
class StickerBundleRetriever {
    static func getStickersFromBundle() -> [URL] {

        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let assetURL = bundleURL.appendingPathComponent("stickers.bundle")

        do {
            let contents = try fileManager.contentsOfDirectory(at: assetURL, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles)

            return contents

        }
        catch let error as NSError {
            return []
        }
    }
}
