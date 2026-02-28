import Foundation

/// Protocol for supported property values.
public protocol Value {}
extension Int: Value {}
extension Double: Value {}
extension String: Value {}
extension Float: Value {}
extension Bool: Value {}

enum AnyCodableValue: Encodable {
    case integer(Int)
    case string(String)
    case float(Float)
    case double(Double)
    case boolean(Bool)
    case null

    init?(from value: Any) {
        switch value {
        case let x as Int:
            self = .integer(x)
        case let x as Double:
            self = .double(x)
        case let x as Float:
            self = .float(x)
        case let x as Bool:
            self = .boolean(x)
        case let x as String:
            self = .string(x)
        case _ as NSNull:
            self = .null
        default:
            return nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .integer(x):
            try container.encode(x)
        case let .string(x):
            try container.encode(x)
        case let .float(x):
            try container.encode(x)
        case let .double(x):
            try container.encode(x)
        case let .boolean(x):
            try container.encode(x)
        case .null:
            try container.encode(self)
        }
    }
}
