//
//  ManualGoalDraftTests.swift
//  DayPlannerTests
//
//  Tests de l'étape 3 : création manuelle d'un objectif + tâche.
//

import Foundation
import Testing
@testable import DayPlanner

struct ManualGoalDraftTests {
    @Test func validDraftBuildsGoalWithOneTask() throws {
        let deadline = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = ManualGoalDraft(
            rawInput: "  Préparer un entretien full-stack  ",
            goalTitle: "  Entretien full-stack  ",
            deadline: deadline,
            taskTitle: "  Réviser SwiftUI  ",
            taskTypeName: "  frontend  ",
            estimatedHours: 4,
            sessionMinutes: 45,
            priority: .high,
            reasoning: "  Important pour le poste  "
        )

        let result = try draft.buildGoal()

        #expect(result.goal.rawInput == "Préparer un entretien full-stack")
        #expect(result.goal.title == "Entretien full-stack")
        #expect(result.goal.deadline == deadline)
        #expect(result.task.title == "Réviser SwiftUI")
        #expect(result.task.estimatedDuration == 4 * 60 * 60)
        #expect(result.task.rhythm.sessionDuration == 45 * 60)
        #expect(result.task.rhythm.frequency == .once)
        #expect(result.task.priority == .high)
        #expect(result.task.reasoning == "Important pour le poste")
        #expect(result.task.type?.name == "frontend")
        #expect(result.goal.tasks.count == 1)
        #expect(result.goal.tasks.first === result.task)
        #expect(result.task.goal === result.goal)
    }

    @Test func taskTypeIsOptional() throws {
        let draft = ManualGoalDraft(
            rawInput: "Appeler le dentiste",
            goalTitle: "Appeler le dentiste",
            taskTitle: "Appeler le cabinet",
            taskTypeName: "   ",
            estimatedHours: 0.5,
            sessionMinutes: 30,
            priority: .medium
        )

        let result = try draft.buildGoal()

        #expect(result.task.type == nil)
    }

    @Test func blankGoalTitleIsRejected() {
        let draft = ManualGoalDraft(
            rawInput: "Quelque chose",
            goalTitle: "   ",
            taskTitle: "Tâche",
            estimatedHours: 1,
            sessionMinutes: 30,
            priority: .medium
        )

        #expect(throws: ManualGoalDraft.ValidationError.blankGoalTitle) {
            try draft.buildGoal()
        }
    }

    @Test func blankTaskTitleIsRejected() {
        let draft = ManualGoalDraft(
            rawInput: "Objectif",
            goalTitle: "Objectif",
            taskTitle: "   ",
            estimatedHours: 1,
            sessionMinutes: 30,
            priority: .medium
        )

        #expect(throws: ManualGoalDraft.ValidationError.blankTaskTitle) {
            try draft.buildGoal()
        }
    }

    @Test func nonPositiveDurationsAreRejected() {
        let invalidEstimated = ManualGoalDraft(
            rawInput: "Objectif",
            goalTitle: "Objectif",
            taskTitle: "Tâche",
            estimatedHours: 0,
            sessionMinutes: 30,
            priority: .medium
        )
        let invalidSession = ManualGoalDraft(
            rawInput: "Objectif",
            goalTitle: "Objectif",
            taskTitle: "Tâche",
            estimatedHours: 1,
            sessionMinutes: 0,
            priority: .medium
        )

        #expect(throws: ManualGoalDraft.ValidationError.nonPositiveEstimatedDuration) {
            try invalidEstimated.buildGoal()
        }
        #expect(throws: ManualGoalDraft.ValidationError.nonPositiveSessionDuration) {
            try invalidSession.buildGoal()
        }
    }
}
