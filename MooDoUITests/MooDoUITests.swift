import XCTest

final class MooDoUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testReorderingFromGripPreservesCompletionGroups() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        let input = app.textFields.firstMatch
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        for title in ["First task", "Second task", "Third task", "Completed task"] {
            input.click()
            input.typeText(title + "\n")
            XCTAssertTrue(app.checkBoxes[title].waitForExistence(timeout: 3))
        }
        app.checkBoxes["Completed task"].click()

        let first = app.checkBoxes["First task"]
        let second = app.checkBoxes["Second task"]
        let third = app.checkBoxes["Third task"]
        let completed = app.checkBoxes["Completed task"]
        let grip = first.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
            .withOffset(CGVector(dx: -15, dy: 0))
        let belowThird = third.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        grip.press(forDuration: 0.1, thenDragTo: belowThird, withVelocity: .slow, thenHoldForDuration: 1)

        XCTAssertTrue(second.waitForExistence(timeout: 3))
        XCTAssertLessThan(second.frame.minY, third.frame.minY)
        XCTAssertLessThan(third.frame.minY, first.frame.minY)

        let completedGrip = completed.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
            .withOffset(CGVector(dx: -15, dy: 0))
        completedGrip.press(forDuration: 0.1, thenDragTo: second.coordinate(withNormalizedOffset: .zero))
        XCTAssertGreaterThan(completed.frame.minY, first.frame.minY)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Custom reorder result"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
