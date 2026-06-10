//
//  NaturalLanguageDraftMappingTests.swift
//  DayPlannerTests
//
//  Tests de l'étape 4 : mapping pur sortie LLM -> brouillons manuels.
//  Aucun appel FoundationModels ici : le modèle est testé par spike/manual validation.
//

import Foundation
import Testing
@testable import DayPlanner

struct NaturalLanguageDraftMappingTests {
    @Test func extractedDraftMapsEachTaskToManualGoalDraft() throws {
        let extracted = ExtractedGoalDraft(
            rawInput: "Je dois préparer un entretien full-stack dans un mois.",
            goalTitle: " Préparer entretien full-stack ",
            deadlineDate: "2026-07-10",
            tasks: [
                ExtractedTaskDraft(
                    title: " Réviser SwiftUI ",
                    typeName: " Frontend ",
                    totalMinutes: 240,
                    sessionMinutes: 45,
                    priority: "high",
                    rationale: "Utile pour les questions iOS."
                ),
                ExtractedTaskDraft(
                    title: "Faire un mock interview",
                    typeName: "",
                    totalMinutes: 90,
                    sessionMinutes: 30,
                    priority: "medium",
                    rationale: "Valider la communication."
                )
            ]
        )

        let drafts = extracted.toManualGoalDrafts(calendar: fixedUTCMockCalendar)

        #expect(drafts.count == 2)
        #expect(drafts[0].rawInput == "Je dois préparer un entretien full-stack dans un mois.")
        #expect(drafts[0].goalTitle == "Préparer entretien full-stack")
        #expect(drafts[0].taskTitle == "Réviser SwiftUI")
        #expect(drafts[0].taskTypeName == "frontend")
        #expect(drafts[0].estimatedHours == 4)
        #expect(drafts[0].sessionMinutes == 45)
        #expect(drafts[0].priority == .high)
        #expect(drafts[0].reasoning == "Utile pour les questions iOS.")

        #expect(drafts[1].taskTitle == "Faire un mock interview")
        #expect(drafts[1].taskTypeName == "")
        #expect(drafts[1].estimatedHours == 1.5)
        #expect(drafts[1].sessionMinutes == 30)
        #expect(drafts[1].priority == .medium)

        let deadline = try #require(drafts[0].deadline)
        let components = fixedUTCMockCalendar.dateComponents([.year, .month, .day], from: deadline)
        #expect(components.year == 2026)
        #expect(components.month == 7)
        #expect(components.day == 10)
    }

    @Test func invalidPriorityFallsBackToMedium() {
        let extracted = ExtractedGoalDraft(
            rawInput: "Objectif",
            goalTitle: "Objectif",
            deadlineDate: "",
            tasks: [
                ExtractedTaskDraft(
                    title: "Tâche",
                    typeName: "admin",
                    totalMinutes: 60,
                    sessionMinutes: 30,
                    priority: "urgent",
                    rationale: ""
                )
            ]
        )

        let drafts = extracted.toManualGoalDrafts(calendar: fixedUTCMockCalendar)

        #expect(drafts.count == 1)
        #expect(drafts[0].priority == .medium)
        #expect(drafts[0].deadline == nil)
    }

    @Test func invalidDeadlineIsIgnored() {
        let extracted = ExtractedGoalDraft(
            rawInput: "Objectif",
            goalTitle: "Objectif",
            deadlineDate: "dans un mois",
            tasks: [
                ExtractedTaskDraft(
                    title: "Tâche",
                    typeName: "revision",
                    totalMinutes: 60,
                    sessionMinutes: 30,
                    priority: "low",
                    rationale: ""
                )
            ]
        )

        let drafts = extracted.toManualGoalDrafts(calendar: fixedUTCMockCalendar)

        #expect(drafts[0].deadline == nil)
        #expect(drafts[0].priority == .low)
    }
}

private var fixedUTCMockCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}
