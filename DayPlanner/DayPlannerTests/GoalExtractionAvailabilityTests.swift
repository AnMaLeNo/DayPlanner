//
//  GoalExtractionAvailabilityTests.swift
//  DayPlannerTests
//
//  Tests purs de la couche d'extraction : messages de disponibilité et contrat public.
//

import Testing
@testable import DayPlanner

struct GoalExtractionAvailabilityTests {
    @Test func availableStatusAllowsExtraction() {
        #expect(GoalExtractionAvailability.available.canExtract)
        #expect(GoalExtractionAvailability.available.userMessage == "Apple Intelligence est disponible.")
    }

    @Test func unavailableStatusBlocksExtractionWithReadableMessage() {
        let status = GoalExtractionAvailability.unavailable("Apple Intelligence n'est pas activé.")

        #expect(!status.canExtract)
        #expect(status.userMessage == "Apple Intelligence n'est pas activé.")
    }

    @Test func unavailableWithoutReasonHasFallbackMessage() {
        let status = GoalExtractionAvailability.unavailable("")

        #expect(!status.canExtract)
        #expect(status.userMessage == "Foundation Models n'est pas disponible sur cet appareil.")
    }
}
