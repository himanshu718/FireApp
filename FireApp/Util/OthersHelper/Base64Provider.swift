//
//  Base64Provider.swift
//  FireApp
//
//  Created by Devlomi on 3/28/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Kingfisher

public struct Base64Provider: ImageDataProvider {

    // MARK: Public Properties
    /// The encoded Base64 string for the image.
    public let base64String: String

    // MARK: Initializers

    /// Creates an image data provider by supplying the Base64 encoded string.
    ///
    /// - Parameters:
    ///   - base64String: The Base64 encoded string for an image.
    ///   - cacheKey: The key is used for caching the image data. You need a different key for any different image.
    public init(base64String: String, cacheKey: String) {
        self.base64String = base64String
        self.cacheKey = cacheKey
    }

    // MARK: Protocol Conforming

    /// The key used in cache.
    public var cacheKey: String

    public func data(handler: (Result<Data, Error>) -> Void) {
        let data = Data(base64Encoded: base64String,options: .ignoreUnknownCharacters) ?? Data()
        handler(.success(data))
    }
}
