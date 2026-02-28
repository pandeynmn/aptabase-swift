//
//  AptabaseNomad.swift
//  Aptabase
//
// Created by pandeynmn on 2/15/26.
// Forked from aptabase-swift
//

import CryptoKit
import Foundation
import SwiftUI

public actor AptabaseNomad {
    private static let sdkVersion = "aptabase-swift-nomad@v1"

    private let dispatcher: EventDispatcher
    private let flushInterval: Double

    private var config: AptabaseConfig

    private var backgroundFlushTask: Task<Void, Never>?
    private var flushTask: Task<Void, Never>?

    private var sessionId: String?

    public init(config: AptabaseConfig) {
        flushInterval = config.flushInterval
        self.config = config
        dispatcher = EventDispatcher(config: config)
        sessionId = Self.generateSessionID(from: config.userID)

        Task.detached {
            await self.startBackgroundFlush()
        }
    }

    // MARK: Internal

    /// Daily calculated session ID that changes every day, based on Vendor ID.
    /// - Parameter userID: Device Vendor ID retreived from UIDevice
    /// - Returns: Hased session ID based on Vendor ID and Current day in the era.
    static func generateSessionID(from userID: UUID) -> String {
        let dayNumber = Self.chicagoCalendar.ordinality(of: .day, in: .era, for: Date())!
        let input = "\(userID.uuidString)-\(dayNumber)"
        let hex = SHA256
            .hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()

        return String(hex.prefix(36))
    }

    /// Automatic background flush task that runs in a loop over the defined time interval.
    /// - Parameter interval: Time Interval in seconds.
    func startBackgroundFlush() {
        // Checking for an existing background flush task in case of an edge cases.
        // This should be nil on initialization and realistically never trigger.
        guard backgroundFlushTask == nil else { return }

        backgroundFlushTask = Task(name: "automatic_background_flush", priority: .background) { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(until: .now + .seconds(config.flushInterval), tolerance: .seconds(1), clock: .continuous)

                } catch {
                    // No need to do anything else if an error arises since this is just a sleep function.
                    // logging it just in case there's a bug with the code instead of this silently failing.
                    debugPrint("Time Interval failed. \(error.localizedDescription)")
                }
                await flush()
                await Task.yield()
            }
        }
    }

    // MARK: Track Events

    /// Tracks an event with a name and no prop body.
    /// - Parameter eventName: Name of the Event to be tracked.
    public func trackEvent(_ eventName: String) async {
        await trackEvent(eventName, codableProps: [:])
    }

    /// Tracks an event with a name and props.
    /// - Parameters:
    ///   - eventName: Name of the event to be displayed in aptabase.
    ///   - props: String and Numeric props associated with the event to be tracked.
    public func trackEvent(_ eventName: String, with props: [String: Any] = [:]) async {
        let codableProps = props.compactMapValues { value in
            if let codableValue = AnyCodableValue(from: value) {
                return codableValue
            } else {
                debugPrint("Aptabase: Unsupported prop value \(value) will be ignored")
                return nil
            }
        }
        await trackEvent(eventName, codableProps: codableProps)
    }

    func trackEvent(_ eventName: String, codableProps: [String: AnyCodableValue] = [:]) async {
        guard let sessionId else {
            debugPrint("UserId or SessionId in trackEvent was found to be nil or has yet to be calculated. This event will be dropped.")
            return
        }
        let newEvent = Event(
            timestamp: Date(),
            userID: config.userID,
            sessionId: sessionId,
            eventName: eventName,
            systemProps: Event.SystemProps(
                isDebug: config.isDebug,
                locale: Locale.current.language.languageCode?.identifier ?? "",
                osName: config.osName,
                osVersion: config.osVersion,
                appVersion: config.appVersion,
                appBuildNumber: config.appBuildNumber,
                sdkVersion: Self.sdkVersion,
                deviceModel: config.deviceModel,
            ),
            props: codableProps,
        )
        await dispatcher.enqueue(newEvent)
    }

    /// Flushes events when called, and returns if a flush event is already underway.
    /// Useful if you need to override the time interval cycle of flushing events and send them
    /// out immediately.
    public func flush() {
        guard flushTask == nil else { return }
        flushTask = Task(priority: .background) {
            await dispatcher.flush()
            self.flushTask = nil
        }
    }
}

extension AptabaseNomad {
    /// Date is tracked in the CST instead of the UTC
    /// because the package author prefers it.
    private static let chicagoCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }()
}
