@testable import Aptabase
import XCTest

class MockURLSession: URLSessionProtocol {
    var requestCount: Int = 0
    var statusCode: Int = 200

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestCount += 1

        let data = "{}".data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

final class EventDispatcherTests: XCTestCase {
    var dispatcher: EventDispatcher!
    var session: MockURLSession!
    let config = AptabaseConfig(appKey: "A-DEV-000", host: URL(string: "http://localhost:3000")!)

    override func setUp() {
        super.setUp()
        session = MockURLSession()
        dispatcher = EventDispatcher(config: config, session: session)
    }

    override func tearDown() {
        dispatcher = nil
        session = nil
        super.tearDown()
    }

    func testFlushEmptyQueue() async {
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 0)
    }

    func testFlushSingleItem() async {
        await dispatcher.enqueue(newEvent("app_started"))

        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
    }

    func testFlushShouldBatchMultipleItems() async {
        await dispatcher.enqueue(newEvent("app_started"))
        await dispatcher.enqueue(newEvent("item_created"))
        await dispatcher.enqueue(newEvent("item_deleted"))

        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)

        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
    }

    func testFlushShouldRetryAfterFailure() async {
        await dispatcher.enqueue(newEvent("app_started"))
        await dispatcher.enqueue(newEvent("item_created"))
        await dispatcher.enqueue(newEvent("item_deleted"))

        session.statusCode = 500
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)

        session.statusCode = 200
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 2)
    }

    private func newEvent(_ eventName: String) -> Event {
        Event(
            timestamp: Date(),
            userID: UUID(),
            sessionId: UUID().uuidString,
            eventName: eventName,
            systemProps: Event.SystemProps(
                isDebug: config.isDebug,
                locale: Locale.current.language.languageCode?.identifier ?? "",
                osName: config.osName,
                osVersion: config.osVersion,
                appVersion: config.appVersion,
                appBuildNumber: config.appBuildNumber,
                sdkVersion: "aptabase-swift-nomad@v1-test",
                deviceModel: config.deviceModel,
            ),
        )
    }
}
