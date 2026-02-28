//
//  Analytics.swift
//  Target
//
// Created by pandeynmn on 2/20/26.
//

import AptabaseNomad
import SwiftUI

@MainActor
final class Metrics {
    static let shared = Metrics()
    private static let key: String = "A-DEV-000"
    private static let host = URL(string: "http://localhost:3000")!

    private let aptabase: AptabaseNomad
    private var flushTask: Task<Void, Never>?

    init() {
        // These configs will work the same for this case. Setting the host yourself is meant for custom implementation of aptabase.
        /*
         let config = AptabaseConfig(appKey: key) // selects localhost on port 3000 by default.
         let config = AptabaseConfig(appKey: Self.key, host: Self.host, flushTimeInterval: 2.0)
         */
        let config = AptabaseConfig(appKey: Self.key, host: Self.host)
        aptabase = AptabaseNomad(config: config)
    }

    func track(_ event: String, _ options: [String: Value] = [:]) {
        Task(priority: .background) {
            await self.aptabase.trackEvent(event, with: options)
        }
        #if DEBUG
            debugPrint(event + " " + options.debugDescription)
        #endif
    }
}
