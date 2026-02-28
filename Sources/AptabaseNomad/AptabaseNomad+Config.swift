//
//  AptabaseNomad+Config.swift
//  Aptabase
//
// Created by pandeynmn on 2/15/26.
// Forked from aptabase-swift
//

import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
#if canImport(IOKit)
    import IOKit
#endif

enum AptabaseInitError: Error {
    case unsupportedSelfHosted
    case invalidAppKey
}

public struct AptabaseConfig {
    /// Analytics Key provided by aptabase.
    var appKey: String

    var userID: UUID {
        #if os(iOS) || os(tvOS)
            return UIDevice.current.identifierForVendor ?? UUID()
        #elseif os(macOS)
            return getHardwareUUID()
        #else
            return getOrCreateDeviceId()
        #endif
    }

    #if os(macOS)
        func getHardwareUUID() -> UUID {
            let platformExpert = IOServiceGetMatchingService(
                kIOMainPortDefault,
                IOServiceMatching("IOPlatformExpertDevice"),
            )
            let uuid = IORegistryEntryCreateCFProperty(
                platformExpert,
                "IOPlatformUUID" as CFString,
                kCFAllocatorDefault, 0,
            ).takeRetainedValue() as? String
            IOObjectRelease(platformExpert)
            return UUID(uuidString: uuid ?? "") ?? UUID()
        }
    #endif

    #if os(watchOS) || os(visionOS)
        private func getOrCreateDeviceId() -> UUID {
            let key = "AptabaseNomad.deviceId"
            if let stored = UserDefaults.standard.string(forKey: key),
               let uuid = UUID(uuidString: stored)
            {
                return uuid
            }
            let newId = UUID()
            UserDefaults.standard.set(newId.uuidString, forKey: key)
            return newId
        }
    #endif

    /// The domain URL of the Aptabase analytics server used for sending events.
    ///
    /// The actual host depends on the `appKey` region code:
    /// - `A-US-xxxxxxxxxx` → `https://us.aptabase.com`
    /// - `A-EU-xxxxxxxxxx` → `https://eu.aptabase.com`
    /// - `A-DEV-000` → `http://localhost:3000`
    /// - `A-SH-xxxxxxxxxx` → Custom self-hosted instance (your Docker server)
    ///
    var host: URL
    var flushInterval: TimeInterval

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let appBuildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    /// Initialize the Aptabase client with a given appKey and a custom host that may or may not
    /// be aptabase.
    /// - Parameters:
    ///   - appKey: Aptabase provided App Key found in the webpage instructions.
    ///   - customHost: Custom host server to send events.
    public init(appKey: String, host: URL) {
        self.appKey = appKey
        #if DEBUG
            flushInterval = 2.0
        #else
            flushInterval = 60.0
        #endif
        self.host = host
    }

    /// Initializes the Aptabase client with the given `appKey`.
    ///
    /// - Parameter appKey: The app key in the format `A-REGION-XXXXXXXXXX`.
    ///   - `A` is static
    ///   - `REGION` can be:
    ///     - `US` → `https://us.aptabase.com`
    ///     - `EU` → `https://eu.aptabase.com`
    ///     - `DEV` → `http://localhost:3000`
    ///     - `SH` → **Throws `unsupportedSelfHosted`** because a custom host is not provided by the user.
    ///
    /// - Throws:
    ///   - `AptabaseInitError.unsupportedSelfHosted` if the region is `SH` and no host is defined. Use an initializer with your custom host defined.
    ///   - `AptabaseInitError.invalidAppKey` if the `appKey` format is invalid.
    public init?(appKey: String) throws {
        self.appKey = appKey

        // Extract region code (second segment, e.g., "US", "EU", "DEV", "SH")
        let segments = appKey.split(separator: "-")
        guard segments.count > 1 else {
            throw AptabaseInitError.invalidAppKey
        }

        let region = segments[1]

        switch region {
        case "US":
            host = URL(string: "https://us.aptabase.com")!
        case "EU":
            host = URL(string: "https://eu.aptabase.com")!
        case "DEV":
            host = URL(string: "http://localhost:3000")!
        case "SH":
            throw AptabaseInitError.unsupportedSelfHosted
        default:
            throw AptabaseInitError.invalidAppKey
        }

        #if DEBUG
            flushInterval = 2.0
        #else
            flushInterval = 60.0
        #endif
    }

    /// Initialize the Aptabase client with a given appKey and a custom host that may or may not
    /// be aptabase.
    /// - Parameters:
    ///   - appKey: Aptabase provided App Key found in the webpage instructions.
    ///   - host: Custom host server to send events.
    ///   - flushTimeInterval: Time Interval in seconds used to send the cached events. It is recommended to set it to 60 seconds in production.
    public init(appKey: String, host: URL, flushTimeInterval: TimeInterval) {
        self.appKey = appKey
        self.host = host
        flushInterval = flushTimeInterval
    }
}

// MARK: Device Configuration Variables

extension AptabaseConfig {
    var isDebug: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }

    var osName: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
            "macOS"
        #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                return "iPadOS"
            }
            return "iOS"
        #elseif os(watchOS)
            "watchOS"
        #elseif os(tvOS)
            "tvOS"
        #elseif os(visionOS)
            "visionOS"
        #else
            ""
        #endif
    }

    var osVersion: String {
        #if os(macOS)
            let os = ProcessInfo.processInfo.operatingSystemVersion
            return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        #elseif os(iOS) || os(tvOS) || os(visionOS)
            UIDevice.current.systemVersion
        #elseif os(watchOS)
            WKInterfaceDevice.current().systemVersion
        #else
            ""
        #endif
    }

    var deviceModel: String {
        #if os(macOS)
            // `uname` returns x86_64 (or Apple Silicon equivalent) for Macs.
            // Use `sysctlbyname` here instead to get actual model name. If it fails, fall back to `uname`.
            var size = 0
            sysctlbyname("hw.model", nil, &size, nil, 0)
            if size > 0 {
                var model = [CChar](repeating: 0, count: size)
                sysctlbyname("hw.model", &model, &size, nil, 0)
                let deviceModel = String(cString: model)
                // If we got a deviceModel, use it. Else continue to "default" logic.
                if !deviceModel.isEmpty {
                    return deviceModel
                }
            }
        #endif

        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModelIdentifier
        } else {
            var systemInfo = utsname()
            if uname(&systemInfo) == 0 {
                return withUnsafePointer(to: &systemInfo.machine) { ptr in
                    ptr.withMemoryRebound(to: CChar.self, capacity: 1) { machinePtr in
                        String(cString: machinePtr)
                    }
                }
            }
            return ""
        }
    }
}
