//
//  DayPlannerTests.swift
//  DayPlannerTests
//
//  Tests unitaires de base pour l'étape 1.
//

import Testing
@testable import DayPlanner

struct DayPlannerTests {
    @Test func rhythmStoresSessionDurationAndFrequency() async throws {
        let rhythm = Rhythm(sessionDuration: 60 * 60, frequency: .everyNDays(2))

        #expect(rhythm.sessionDuration == 60 * 60)
        #expect(rhythm.frequency == .everyNDays(2))
    }

    @Test func priorityHasThreeMVPLevels() async throws {
        #expect(Priority.allCases == [.high, .medium, .low])
    }
}
