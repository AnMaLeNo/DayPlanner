//
//  ExtractedGoalDraft.swift
//  DayPlanner
//
//  Sortie structurée intermédiaire pour la création depuis une phrase naturelle.
//  Ce fichier reste indépendant de FoundationModels : il est testable sans appeler le LLM.
//

import Foundation

struct ExtractedGoalDraft: Equatable {
    var rawInput: String
    var goalTitle: String
    var deadlineDate: String
    var tasks: [ExtractedTaskDraft]

    func toManualGoalDrafts(calendar: Calendar = .current) -> [ManualGoalDraft] {
        let cleanRawInput = rawInput.nlpTrimmed
        let cleanGoalTitle = goalTitle.nlpTrimmed
        let deadline = deadlineDate.parsedISODate(calendar: calendar)

        return tasks.map { task in
            ManualGoalDraft(
                rawInput: cleanRawInput,
                goalTitle: cleanGoalTitle,
                deadline: deadline,
                taskTitle: task.title.nlpTrimmed,
                taskTypeName: task.typeName.nlpTrimmed.lowercased(),
                estimatedHours: Double(task.totalMinutes) / 60,
                sessionMinutes: Double(task.sessionMinutes),
                priority: Priority(naturalLanguageValue: task.priority),
                reasoning: task.rationale.nlpTrimmed
            )
        }
    }
}

struct ExtractedTaskDraft: Equatable {
    var title: String
    var typeName: String
    var totalMinutes: Int
    var sessionMinutes: Int
    var priority: String
    var rationale: String
}

private extension Priority {
    init(naturalLanguageValue: String) {
        switch naturalLanguageValue.nlpTrimmed.lowercased() {
        case "high":
            self = .high
        case "low":
            self = .low
        default:
            self = .medium
        }
    }
}

private extension String {
    var nlpTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parsedISODate(calendar: Calendar) -> Date? {
        let cleaned = nlpTrimmed
        guard !cleaned.isEmpty else { return nil }

        let parts = cleaned.split(separator: "-").compactMap { Int(String($0)) }
        guard parts.count == 3 else { return nil }

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }
}
