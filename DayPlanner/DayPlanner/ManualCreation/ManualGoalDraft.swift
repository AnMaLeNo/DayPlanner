//
//  ManualGoalDraft.swift
//  DayPlanner
//
//  Brouillon de création manuelle d'un objectif + première tâche.
//  Ce type est volontairement indépendant de SwiftUI : il porte la validation
//  et construit les modèles SwiftData utilisés ensuite par l'interface.
//

import Foundation

struct ManualGoalDraft {
    enum ValidationError: Error, Equatable {
        case blankGoalTitle
        case blankTaskTitle
        case nonPositiveEstimatedDuration
        case nonPositiveSessionDuration
    }

    struct BuildResult {
        let goal: Goal
        let task: PlanTask
    }

    var rawInput: String
    var goalTitle: String
    var deadline: Date?
    var taskTitle: String
    var taskTypeName: String
    var estimatedHours: Double
    var sessionMinutes: Double
    var priority: Priority
    var reasoning: String

    init(
        rawInput: String,
        goalTitle: String,
        deadline: Date? = nil,
        taskTitle: String,
        taskTypeName: String = "",
        estimatedHours: Double,
        sessionMinutes: Double,
        priority: Priority,
        reasoning: String = ""
    ) {
        self.rawInput = rawInput
        self.goalTitle = goalTitle
        self.deadline = deadline
        self.taskTitle = taskTitle
        self.taskTypeName = taskTypeName
        self.estimatedHours = estimatedHours
        self.sessionMinutes = sessionMinutes
        self.priority = priority
        self.reasoning = reasoning
    }

    func buildGoal() throws -> BuildResult {
        let cleanedGoalTitle = goalTitle.trimmedForManualInput
        let cleanedTaskTitle = taskTitle.trimmedForManualInput
        let cleanedRawInput = rawInput.trimmedForManualInput
        let cleanedTaskType = taskTypeName.trimmedForManualInput.lowercased()
        let cleanedReasoning = reasoning.trimmedForManualInput

        guard !cleanedGoalTitle.isEmpty else { throw ValidationError.blankGoalTitle }
        guard !cleanedTaskTitle.isEmpty else { throw ValidationError.blankTaskTitle }
        guard estimatedHours > 0 else { throw ValidationError.nonPositiveEstimatedDuration }
        guard sessionMinutes > 0 else { throw ValidationError.nonPositiveSessionDuration }

        let goal = Goal(
            rawInput: cleanedRawInput.isEmpty ? cleanedGoalTitle : cleanedRawInput,
            title: cleanedGoalTitle,
            deadline: deadline
        )

        let taskType = cleanedTaskType.isEmpty ? nil : TaskType(name: cleanedTaskType)
        let task = PlanTask(
            title: cleanedTaskTitle,
            estimatedDuration: estimatedHours * 60 * 60,
            rhythm: Rhythm(sessionDuration: sessionMinutes * 60, frequency: .once),
            priority: priority,
            reasoning: cleanedReasoning.isEmpty ? "Créé manuellement." : cleanedReasoning,
            goal: goal,
            type: taskType
        )

        goal.tasks.append(task)
        return BuildResult(goal: goal, task: task)
    }
}

private extension String {
    var trimmedForManualInput: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
