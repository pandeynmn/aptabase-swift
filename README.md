![Aptabase](https://aptabase.com/og.png)

# Swift SDK for Aptabase

Updated SwiftUI & Swift 6 concurrency safe Aptabase SDK.
Instrument your apps with Aptabase, an Open Source, Privacy-First and Simple Analytics for Mobile, Desktop and Web Apps.

## Install

#### Option 1: Swift Package Manager

Add the following lines to your `Package.swift` file:

```swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "https://github.com/pandeynmn/aptabase-swift.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["AptabaseNomad"] // Add as a dependency
        )
    ]
)
```

#### Option 2: Adding package dependencies with Xcode

Use this [guide](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) to add `AptabaseNomad` to your project. Use https://github.com/pandeynmn/aptabase-swift.git for the URL when Xcode asks.


## Usage

> If you're targeting macOS, you must first enable the `Outgoing Connections (Client)` checkbox under the `App Sandbox` section.

First, you need to get your `App Key` from Aptabase, you can find it in the `Instructions` menu on the left side menu.

Initialized the SDK as early as possible in your app. Check the AptabaseTestApp for the recommended initialization.

Afterward, you can start tracking events with `trackEvent`:
```swift
await self.aptabase.trackEvent("event_name")

// With props
await self.aptabase.trackEvent("event_name", with: ["key": "value"])

Task(priority: .background) {
    await self.aptabase.trackEvent("event_name", with: ["key": "value"])
}
```


A few important notes:

1. The SDK will automatically enhance the event with some useful information, like the OS, the app version, and other things.
2. You're in control of what gets sent to Aptabase. This SDK does not automatically track any events, you need to call `trackEvent` manually.
   - Because of this, it's generally recommended to at least track an event at startup
3. `trackEvent` is an `async` function — call it with `await` to control the task priority and concurrency context it runs in.
4. Only strings and numbers values are allowed on custom properties

## Preparing for Submission to Apple App Store

When submitting your app to the Apple App Store, you'll need to fill out the `App Privacy` form. You can find all the answers on our [How to fill out the Apple App Privacy when using Aptabase](https://aptabase.com/docs/apple-app-privacy) guide.
