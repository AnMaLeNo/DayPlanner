//
//  RelativeDeadlineResolver.swift
//  DayPlanner
//
//  Corrige les deadlines relatives explicites que le LLM peut mal calculer.
//  Exemple : depuis jeudi 2026-06-11, "lundi prochain" = 2026-06-15.
//

import Foundation

struct RelativeDeadlineResolver {
    static func deadlineDateString(
        in rawInput: String,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        let normalizedInput = rawInput.normalizedForRelativeDeadline

        guard let targetWeekday = weekdayMentionedWithNext(in: normalizedInput) else {
            return nil
        }

        let startOfReferenceDay = calendar.startOfDay(for: referenceDate)
        let currentWeekday = calendar.component(.weekday, from: startOfReferenceDay)
        let rawDelta = (targetWeekday - currentWeekday + 7) % 7
        let daysUntilTarget = rawDelta == 0 ? 7 : rawDelta

        guard let deadline = calendar.date(
            byAdding: .day,
            value: daysUntilTarget,
            to: startOfReferenceDay
        ) else {
            return nil
        }

        let components = calendar.dateComponents([.year, .month, .day], from: deadline)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }

        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func weekdayMentionedWithNext(in normalizedInput: String) -> Int? {
        for (weekdayName, weekdayValue) in frenchWeekdays {
            if normalizedInput.contains("\(weekdayName) prochain") ||
                normalizedInput.contains("prochain \(weekdayName)") ||
                normalizedInput.contains("\(weekdayName) prochaine") ||
                normalizedInput.contains("prochaine \(weekdayName)") {
                return weekdayValue
            }
        }
        return nil
    }

    // Calendar weekday values: Sunday = 1, Monday = 2, ..., Saturday = 7.
    private static let frenchWeekdays: [(String, Int)] = [
        ("dimanche", 1),
        ("lundi", 2),
        ("mardi", 3),
        ("mercredi", 4),
        ("jeudi", 5),
        ("vendredi", 6),
        ("samedi", 7)
    ]
}

extension ExtractedGoalDraft {
    func correctingRelativeDeadline(
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ExtractedGoalDraft {
        guard let resolvedDeadline = RelativeDeadlineResolver.deadlineDateString(
            in: rawInput,
            referenceDate: referenceDate,
            calendar: calendar
        ) else {
            return self
        }

        var corrected = self
        corrected.deadlineDate = resolvedDeadline
        return corrected
    }
}

private extension String {
    var normalizedForRelativeDeadline: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
    }
}
