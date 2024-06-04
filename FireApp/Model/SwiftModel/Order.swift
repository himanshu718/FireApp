//
//  VendorOrder.swift
//  FireApp
//
//  Created by Kartik Gupta on 14/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import Foundation

struct Order: Codable {
    let status: String?
    let assignedAtPrice: Int?
    let assignedBidId, assignedUserId, assignedUserName: String?
    let bidderIDs: [String]?
    let completed: Bool?
    let delivery, image: String?
    let netsRequired: Int?
    let orderDiscription, orderId, pickup: String?
    let price: Int?
    let size: String?
    let timestamp: Int64?
    let vendorId, vendorName, weight: String?
    let state : String?
    
    let vendorReview : String?
    let vendorRating : Float?
    let operatorReview : String?
    let operatorRating : Float?
    
    let vehicleType : String?
    
//    let deliveryLatLng: [String: Double]?
//    let pickupLatLng: [String: Double]?
    
    enum CodingKeys: String, CodingKey {
        case status, assignedAtPrice
        case assignedBidId
        case assignedUserId
        case assignedUserName, bidderIDs, completed, delivery, image, netsRequired, orderDiscription
        case orderId
        case pickup, price, size, timestamp
        case vendorId
        case vendorName, weight
        case state
        case vendorReview
        case vendorRating
        case operatorReview
        case operatorRating
        case vehicleType
//        case deliveryLatLng
//        case pickupLatLng
    }
}

// MARK: Order convenience initializers and mutators

extension Order {
    init(data: Data) throws {
        self = try JSONDecoder().decode(Order.self, from: data)
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
        status: String?? = nil,
        assignedAtPrice: Int?? = nil,
        assignedBidId: String?? = nil,
        assignedUserId: String?? = nil,
        assignedUserName: String?? = nil,
        bidderIDs: [String]?? = nil,
        completed: Bool?? = nil,
        delivery: String?? = nil,
        image: String?? = nil,
        netsRequired: Int?? = nil,
        orderDiscription: String?? = nil,
        orderId: String?? = nil,
        pickup: String?? = nil,
        price: Int?? = nil,
        size: String?? = nil,
        timestamp: Int64?? = nil,
        vendorId: String?? = nil,
        vendorName: String?? = nil,
        weight: String?? = nil,
        state : String?? = nil,
        
        vendorReview : String?? = nil,
        vendorRating : Float?? = nil,
        operatorReview : String?? = nil,
        operatorRating : Float?? = nil,
        
        vehicleType : String?? = nil
        
//        deliveryLatLng: [String: Double]?? = nil,
//        pickupLatLng: [String: Double]?? = nil
        
    ) -> Order {
        return Order(
            status: status ?? self.status,
            assignedAtPrice: assignedAtPrice ?? self.assignedAtPrice,
            assignedBidId: assignedBidId ?? self.assignedBidId,
            assignedUserId: assignedUserId ?? self.assignedUserId,
            assignedUserName: assignedUserName ?? self.assignedUserName,
            bidderIDs: bidderIDs ?? self.bidderIDs,
            completed: completed ?? self.completed,
            delivery: delivery ?? self.delivery,
            image: image ?? self.image,
            netsRequired: netsRequired ?? self.netsRequired,
            orderDiscription: orderDiscription ?? self.orderDiscription,
            orderId: orderId ?? self.orderId,
            pickup: pickup ?? self.pickup,
            price: price ?? self.price,
            size: size ?? self.size,
            timestamp: timestamp ?? self.timestamp,
            vendorId: vendorId ?? self.vendorId,
            vendorName: vendorName ?? self.vendorName,
            weight: weight ?? self.weight,
            state : state ?? self.state,
            
            vendorReview : vendorReview ?? self.vendorReview,
            vendorRating : vendorRating ?? self.vendorRating,
            operatorReview : operatorReview ?? self.operatorReview,
            operatorRating : operatorRating ?? self.operatorRating,
            
            vehicleType : vehicleType ?? self.vehicleType
            
            
//            deliveryLatLng: deliveryLatLng ?? self.deliveryLatLng,
//            pickupLatLng: pickupLatLng ?? self.pickupLatLng
        )
    }

    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

