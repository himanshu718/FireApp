//
//  Bid.swift
//  FireApp
//
//  Created by Kartik Gupta on 29/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import Foundation

// MARK: - Bid
struct Bid: Codable {
    let priceRequired: Int?
    let vendorName, vendorId: String?
    let priceoffered: Int?
    let accepted: Bool?
    let timestamp: Double?
    let netsUsed, netsRequired: Int?
    let orderId, bidderName, userId, bidId: String?

    enum CodingKeys: String, CodingKey {
        case priceRequired, vendorName
        case vendorId
        case priceoffered, accepted, netsUsed, timestamp, netsRequired
        case orderId
        case bidderName
        case userId
        case bidId
    }
}

// MARK: Bid convenience initializers and mutators

extension Bid {
    init(data: Data) throws {
        self = try JSONDecoder().decode(Bid.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        priceRequired: Int?? = nil,
        vendorName: String?? = nil,
        vendorId: String?? = nil,
        priceoffered: Int?? = nil,
        accepted: Bool?? = nil,
        timestamp: Double?? = nil,
        netsUsed: Int?? = nil,
        netsRequired: Int?? = nil,
        orderId: String?? = nil,
        bidderName: String?? = nil,
        userId: String?? = nil,
        bidId: String?? = nil
    ) -> Bid {
        return Bid(
            priceRequired: priceRequired ?? self.priceRequired,
            vendorName: vendorName ?? self.vendorName,
            vendorId: vendorId ?? self.vendorId,
            priceoffered: priceoffered ?? self.priceoffered,
            accepted: accepted ?? self.accepted,
            timestamp: timestamp ?? self.timestamp,
            netsUsed: netsUsed ?? self.netsUsed,
            netsRequired: netsRequired ?? self.netsRequired,
            orderId: orderId ?? self.orderId,
            bidderName: bidderName ?? self.bidderName,
            userId: userId ?? self.userId,
            bidId: bidId ?? self.bidId
        )
    }

    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
