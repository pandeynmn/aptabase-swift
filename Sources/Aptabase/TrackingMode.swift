import Foundation

/// Represents the tracking mode (release/debug) for the client.
@objc public class TrackingMode: NSObject, Codable {
    @objc public static let asDebug = TrackingMode(rawValue: 0)
    @objc public static let asRelease = TrackingMode(rawValue: 1)
    private let rawValue: Int

    private init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public var isDebug: Bool {
        rawValue == 0
    }

    public var isRelease: Bool {
        rawValue == 1
    }
}
