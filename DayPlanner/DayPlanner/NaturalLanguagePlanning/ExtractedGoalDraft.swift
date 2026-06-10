//
//  ExtractedGoalDraft.swift
//  DayPlanner
//
//  Sortie structurée intermédiaire pour la création depuis une phrase naturelle.
//  Les types publics restent testables sans appeler le LLM ; les types Generated*
//  décrivent seulement le schéma FoundationModels.
//

import Foundation
import FoundationModels

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

@Generable
struct GeneratedGoalDraft {
    @Guide(description: "Titre court et clair de l'objectif")
    let goalTitle: String

    @Guide(description: "Deadline ISO yyyy-MM-dd si détectable, sinon chaîne vide")
    let deadlineDate: String

    @Guide(description: "Tâches concrètes", .count(1...5))
    let tasks: [GeneratedTaskDraft]

    func extracted(rawInput: String) -> ExtractedGoalDraft {
        ExtractedGoalDraft(
            rawInput: rawInput,
            goalTitle: goalTitle,
            deadlineDate: deadlineDate,
            tasks: tasks.map { $0.extracted() }
        )
    }
}

@Generable
struct GeneratedTaskDraft {
    @Guide(description: "Titre court de la tâche")
    let title: String

    @Guide(description: "Type court en minuscules : frontend, backend, design, admin, revision, autre")
    let typeName: String

    @Guide(description: "Durée totale estimée en minutes", .range(15...2400))
    let totalMinutes: Int

    @Guide(description: "Durée recommandée d'une session en minutes", .range(15...180))
    let sessionMinutes: Int

    @Guide(description: "Priorité : low, medium ou high")
    let priority: String

    @Guide(description: "Explication courte du choix")
    let rationale: String

    func extracted() -> ExtractedTaskDraft {
        ExtractedTaskDraft(
            title: title,
            typeName: typeName,
            totalMinutes: totalMinutes,
            sessionMinutes: sessionMinutes,
            priority: priority,
            rationale: rationale
        )
    }
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
