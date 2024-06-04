//
//  FirebaseManager.swift
//  FireApp
//
//  Created by on 21/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseFunctions
import FirebaseDatabase
import FirebaseFirestore

public typealias FirebaseSyncCompletion = (_ snapshot: DataSnapshot?, _ error: Error?) -> Void
public typealias FireStoreFetchCompletion = (_ documentData: [String: Any]?, _ error: Error?) -> Void
public typealias FireStoreCompletion = (_ documentData: [Any]?, _ error: Error?) -> Void
public typealias FireStoreArrayFetchCompletion = (_ dataArray: [[String: Any]]?, _ error: Error?) -> Void
public typealias FireStoreArrayCompletion = (_ dataArray: [Any]?, _ error: Error?) -> Void
public typealias FireBaseFetchCompletion = (_ data: [String: Any]?, _ error: Error?) -> Void

enum UploadImageType {
    case ceoImage
    case idImage
    case profileImage
    case orderImage
    case govId
    case utilityBill
}

class FirebaseManager: NSObject {
    static let sharedFirebaseManager = FirebaseManager()
    let db = Firestore.firestore()
    lazy var functions = Functions.functions()
    var refHandle: DatabaseHandle?
    
    let ORDERID: String = "orderId"
    let VENDERID: String = "vendorId"
    let TIMESTAMP: String = "timestamp"
    let STATE: String = "state"
    let VEHICLE_TYPE: String = "vehicleType"
    let STATUS: String = "status"
    let COMPLETED: String = "COMPLETED"
    let ASSIGNED: String = "ASSIGNED"
    let CREATED: String = "CREATED"
    let BIDDER_IDS: String = "bidderIDs"
    let ACCEPTED: String = "accepted"
    
    let ASSIGNED_USER_ID: String = "assignedUserId"
    let ASSIGNED_AT_PRICE: String = "assignedAtPrice"
    let ASSIGNED_USER_NAME: String = "assignedUserName"
    let ASSIGNED_BID_ID: String = "assignedBidId"
    
    override init() {
        super.init()
//        Database.database().isPersistenceEnabled = true
    }

    func getVendorOrders(_ assigned: Bool = false, _ completed: Bool = false, completion: FireStoreArrayFetchCompletion? = nil) {
        
        var query = db.collection(Config.COLLECTION_ORDERS).whereField(VENDERID, isEqualTo: FireManager.getUid()).whereField(STATUS, isEqualTo: CREATED).order(by: TIMESTAMP, descending: true)
        if assigned {
            query = db.collection(Config.COLLECTION_ORDERS).whereField(VENDERID, isEqualTo: FireManager.getUid()).whereField(STATUS, isEqualTo: ASSIGNED).order(by: TIMESTAMP, descending: true)
        }
        if completed {
            query = db.collection(Config.COLLECTION_ORDERS).whereField(VENDERID, isEqualTo: FireManager.getUid()).whereField(STATUS, isEqualTo: COMPLETED).order(by: TIMESTAMP, descending: true)
        }

        query.addSnapshotListener{ querySnapshot, error in
            if error != nil {
                print("getVendorOrders ... \(error)")
                completion?(nil, error)
            } else {
                if let querySnapshot = querySnapshot {
                    var arr = [[String: Any]]()
                    print(querySnapshot.documents)
                    for document in querySnapshot.documents {
                        arr.append(document.data())
                    }
                    
                    print(arr)
                    
                    completion?(arr, nil)
                } else {
                    completion?(nil, NSError.init(domain: "No document exists", code: 21, userInfo: nil))
                }
            }
        }
    }

    func getBidsOnOrder(_ orderId: String, completion: FireStoreArrayFetchCompletion? = nil) {
        db.collection(Config.COLLECTION_BIDS).whereField(ORDERID, isEqualTo: orderId).order(by: TIMESTAMP, descending: true).addSnapshotListener{ querySnapshot, error in
            if error != nil {
                print("getBidsOnOrder... \(error)")
                completion?(nil, error)
            } else {
                if let querySnapshot = querySnapshot {
                    var arr = [[String: Any]]()
                    for document in querySnapshot.documents {
                        arr.append(document.data())
                    }
                    completion?(arr, nil)
                    
                } else {
                    completion?(nil, NSError.init(domain: "No document exists", code: 21, userInfo: nil))
                }
            }
        }
    }
    
    func assignOrder(order: Order, bid: Bid, completion: @escaping (_ error: Error?) -> Void) {
        let batch = db.batch()
        batch.updateData([ACCEPTED: true], forDocument: db.collection(Config.COLLECTION_BIDS).document(bid.bidId!))
        batch.updateData([STATUS: ASSIGNED], forDocument: db.collection(Config.COLLECTION_ORDERS).document(bid.orderId!))
        batch.updateData([ASSIGNED_USER_ID: bid.userId!], forDocument: db.collection(Config.COLLECTION_ORDERS).document(bid.orderId!))
        batch.updateData([ASSIGNED_AT_PRICE: bid.priceoffered!], forDocument: db.collection(Config.COLLECTION_ORDERS).document(bid.orderId!))
        batch.updateData([ASSIGNED_USER_NAME: bid.bidderName!], forDocument: db.collection(Config.COLLECTION_ORDERS).document(bid.orderId!))
        batch.updateData([ASSIGNED_BID_ID: bid.bidId!], forDocument: db.collection(Config.COLLECTION_ORDERS).document(bid.orderId!))
        batch.commit { error in
            if error == nil {
                self.updateNetData(bid.netsUsed ?? 0, bid.userId ?? "", completion: completion)
            } else {
                completion(error)
            }
        }
    }
    
    func getOrdersForDeliveryOperator(_ created : Bool = false, _ assignedToMe: Bool = false, _ completed: Bool = false, completion: FireStoreArrayFetchCompletion? = nil) {
        
        var query = db.collection(Config.COLLECTION_ORDERS).whereField(STATUS, isEqualTo: CREATED).order(by: TIMESTAMP, descending: true)
        if created {
            query = db.collection(Config.COLLECTION_ORDERS).whereField(BIDDER_IDS, arrayContains: FireManager.getUid()).whereField(STATUS, isEqualTo: CREATED).order(by: TIMESTAMP, descending: true)
        } else if assignedToMe {
            query = db.collection(Config.COLLECTION_ORDERS).whereField(ASSIGNED_USER_ID, isEqualTo: FireManager.getUid()).whereField(STATUS, isEqualTo: ASSIGNED).order(by: TIMESTAMP, descending: true)
        } else if completed {
            query = db.collection(Config.COLLECTION_ORDERS).whereField(ASSIGNED_USER_ID, isEqualTo: FireManager.getUid()).whereField(STATUS, isEqualTo: COMPLETED).order(by: TIMESTAMP, descending: true)
        }
        
        query.addSnapshotListener{ querySnapshot, error in
            if error != nil {
                completion?(nil, error)
            } else {
                if let querySnapshot = querySnapshot {
                    var arr = [[String: Any]]()
                    for document in querySnapshot.documents {
                        arr.append(document.data())
                    }
                    completion?(arr, nil)
                } else {
                    completion?(nil, NSError.init(domain: "No document exists", code: 21, userInfo: nil))
                }
            }
        }
    }
    
    func bidOnOrder(bid: Bid, completion: @escaping (_ error: Error?) -> Void) {
        let batch = db.batch()

        let bidRefernce = db.collection(Config.COLLECTION_BIDS).document()
        
        let updatedBid = Bid.init(priceRequired: bid.priceRequired, vendorName: bid.vendorName, vendorId: bid.vendorId, priceoffered: bid.priceoffered, accepted: bid.accepted, timestamp: bid.timestamp, netsUsed: bid.netsUsed, netsRequired: bid.netsRequired, orderId: bid.orderId, bidderName: bid.bidderName, userId: bid.userId, bidId: bidRefernce.documentID)
        
        do {
            let encodedJson = try updatedBid.jsonData()
            if let data = try JSONSerialization.jsonObject(with: encodedJson, options: .mutableLeaves) as? [String: Any] {
                batch.setData(data, forDocument: bidRefernce)

                batch.updateData([
                    BIDDER_IDS: FieldValue.arrayUnion([FireManager.getUid()])
                ], forDocument: db.collection(Config.COLLECTION_ORDERS).document(updatedBid.orderId!))
                
                batch.commit { error in
                    if error == nil {
//                        self.updateNetData(bid.netsUsed ?? 0, completion: completion)
                    } else {
                        completion(error)
                    }
                }
            }
        } catch let error {
            completion(error)
        }
    }
    
    func updateNetData(_ netUsed: Int,_ biderUid: String, completion: @escaping (_ error: Error?) -> Void) {
        let ref = FireConstants.usersRef.child(biderUid)
        ref.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                let error = NSError(domain: "", code: 1001, userInfo: [ NSLocalizedDescriptionKey: "Snapshot not exist."])
                print("updateNetData .... \(error)")
                completion(error)
                return
            }
            
            
            if let nets = snapshot.childSnapshot(forPath: "netsAvailable").value as? Int {
                let totalNets = nets - netUsed
                ref.child("netsAvailable").setValue(totalNets)
                completion(nil)
            } else {
                let error = NSError(domain: "", code: 1001, userInfo: [ NSLocalizedDescriptionKey: "Net field not available"])
                completion(error)
            }
        }
    }
    
    func getAssignedBid(order: Order, completion: FireStoreArrayFetchCompletion? = nil) {
        db.collection(Config.COLLECTION_BIDS).whereField("bidId", isEqualTo: order.assignedBidId!).addSnapshotListener{ querySnapshot, error in
            if error != nil {
                print("getAssignedBid.... \(error)")
                completion?(nil, error)
            } else {
                if let querySnapshot = querySnapshot {
                    var arr = [[String: Any]]()
                    for document in querySnapshot.documents {
                        arr.append(document.data())
                    }
                    completion?(arr, nil)
                } else {
                    completion?(nil, NSError.init(domain: "No document exists", code: 21, userInfo: nil))
                }
            }
        }
    }
    
    func uploadMedia(_ orderId: String? = "",_ imageType: UploadImageType, uploadData: Data, completion: @escaping (_ error: Error?, _ url: String?) -> Void) {
        var lastStr = ""
        switch imageType {
        case .ceoImage:
            lastStr = "ceoImage"
        case .idImage:
            lastStr = "idImage"
        case .profileImage:
            lastStr = "profileImage"
        case .orderImage:
            lastStr = (orderId ?? "") + "orderImage"
        case .govId:
            lastStr = "govId"
        case .utilityBill:
            lastStr = "utilityBill"
        }
        let storageRef = Storage.storage().reference().child("\(FireManager.getUid())_\(lastStr).png")
        storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
            if error != nil {
                print("uploadMedia... \(error)")
                completion(error, nil)
            } else {
                
                storageRef.downloadURL(completion: { (url, error) in
                    completion(nil, url?.absoluteString)
                })
            }
        }
    }
    
    func markOrderComplete(_ order: Order, _ vendorRating: Float, _ vendorReview: String,  _ operatorRating : Float , _ operatorReview : String,  completion: @escaping (_ error: Error?) -> Void) {
        let batch = db.batch()
        // Create a ref with auto-generated ID
        
        batch.updateData([STATUS: COMPLETED], forDocument: db.collection(Config.COLLECTION_ORDERS).document(order.orderId!))
        batch.updateData(["vendorReview" : vendorReview], forDocument: db.collection(Config.COLLECTION_ORDERS).document(order.orderId!))
        batch.updateData(["vendorRating" : vendorRating], forDocument: db.collection(Config.COLLECTION_ORDERS).document(order.orderId!))
        batch.updateData(["operatorRating" : operatorRating], forDocument: db.collection(Config.COLLECTION_ORDERS).document(order.orderId!))
        batch.updateData(["operatorReview" : operatorReview], forDocument: db.collection(Config.COLLECTION_ORDERS).document(order.orderId!))
        batch.updateData(["completed": true], forDocument: db.collection(Config.COLLECTION_BIDS).document(order.assignedBidId!))
        batch.commit { error in
            print("markOrderComplete....  \(error)")
            completion(error)
        }
    }
    
    func getPromotionAvailability(completion: @escaping (_ isPromotion: Bool?, _ error: Error?) -> Void) {
        let docRef = db.collection("remoteconfig").document("data")
        
        docRef.getDocument{ document, error in
            if error != nil {
                print("getPromotionAvailability ... \(error)")
                completion(false, error)
            } else {
                if let document = document, document.exists {
                    do {
                        let value = document.get("isPromotionPeriod") as? Bool
                        completion(value, nil)
                    } catch {
                        let error = NSError(domain: "", code: 1001, userInfo: [ NSLocalizedDescriptionKey: "Something went wrong"])
                        completion(false, error)
                    }
                } else {
                    let error = NSError(domain: "", code: 1001, userInfo: [ NSLocalizedDescriptionKey: "Something went wrong"])
                    completion(false, error)
                }
            }
        }
    }
}
