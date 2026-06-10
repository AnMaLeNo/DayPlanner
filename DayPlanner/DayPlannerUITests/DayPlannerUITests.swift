//
//  DayPlannerUITests.swift
//  DayPlannerUITests
//
//  Tests UI minimaux de fumée. La logique métier est testée côté DayPlannerTests.
//

import XCTest

final class DayPlannerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testManualGoalCreationEntryPointIsVisible() throws {
        let app = XCUIApplication()
        app.launch()

        let createButton = app.buttons["manual-goal-create-button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
    }
}
