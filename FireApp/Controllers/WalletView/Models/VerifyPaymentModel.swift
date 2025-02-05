// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let verifyPayment = try? JSONDecoder().decode(VerifyPayment.self, from: jsonData)

import Foundation

// MARK: - VerifyPayment
// MARK: - InitPayment
struct InitPayment: Codable {
    let status: Bool?
    let message: String?
    let data: InitData?
}

// MARK: - DataClass
struct InitData: Codable {
    let authorizationURL: String?
    let accessCode, reference: String?

    enum CodingKeys: String, CodingKey {
        case authorizationURL = "authorization_url"
        case accessCode = "access_code"
        case reference
    }
}

struct VerifyPayment: Codable {
    let status: Bool?
    let message: String?
    let data: VerificationData?
}

// MARK: - DataClass
struct VerificationData: Codable {
    let id: Int?
    let domain, status, reference: String?
    let amount: Int?
    let message, gatewayResponse, dataPaidAt, dataCreatedAt: String?
    let channel, currency, ipAddress, metadata: String?
    let log: Log?
    let fees: Int?
    let feesSplit: String?
    let authorization: Authorization?
    let customer: Customer?
    let plan: String?
    let split: PlanObject?
    let orderID, paidAt, createdAt: String?
    let requestedAmount: Int?
    let posTransactionData, source, transactionDate: String?
    let planObject, subaccount: PlanObject?
    let fees_breakdown: [FeesBreakdown]?

    enum CodingKeys: String, CodingKey {
        case id, domain, status, reference, amount, message
        case gatewayResponse = "gateway_response"
        case dataPaidAt = "paid_at"
        case dataCreatedAt = "created_at"
        case channel, currency
        case ipAddress = "ip_address"
        case metadata, log, fees
        case feesSplit = "fees_split"
        case authorization, customer, plan, split
        case orderID = "order_id"
        case paidAt, createdAt
        case requestedAmount = "requested_amount"
        case posTransactionData = "pos_transaction_data"
        case source, transactionDate
        case planObject = "plan_object"
        case subaccount
        case fees_breakdown = "fees_breakdown"
    }
}

struct FeesBreakdown: Codable {
    let amountFees: Int?
    let formulaFees: String?
    let typeFees: String?

    enum CodingKeys: String, CodingKey {
        case amountFees = "amount"
        case formulaFees = "formula"
        case typeFees = "type"
    }
}


// MARK: - Authorization
struct Authorization: Codable {
    let authorizationCode, bin, last4, expMonth: String?
    let expYear, channel, cardType, bank: String?
    let countryCode, brand: String?
    let reusable: Bool?
    let signature, accountName: String?

    enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorization_code"
        case bin, last4
        case expMonth = "exp_month"
        case expYear = "exp_year"
        case channel
        case cardType = "card_type"
        case bank
        case countryCode = "country_code"
        case brand, reusable, signature
        case accountName = "account_name"
    }
}

// MARK: - Customer
struct Customer: Codable {
    let id: Int?
    let firstName, lastName, email, customerCode: String?
    let phone, metadata, riskAction, internationalFormatPhone: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case customerCode = "customer_code"
        case phone, metadata
        case riskAction = "risk_action"
        case internationalFormatPhone = "international_format_phone"
    }
}

// MARK: - Log
struct Log: Codable {
    let startTime, timeSpent, attempts, errors: Int?
    let success, mobile: Bool?
    let input: [JSONAny]?
    let history: [History]?

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case timeSpent = "time_spent"
        case attempts, errors, success, mobile, input, history
    }
}

// MARK: - History
struct History: Codable {
    let type, message: String?
    let time: Int?
}

// MARK: - PlanObject
struct PlanObject: Codable {
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
