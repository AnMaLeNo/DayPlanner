//
//  RelativeDeadlineResolverTests.swift
//  DayPlannerTests
//
//  Régressions sur les deadlines relatives explicites.
//

import Foundation
import Testing
@testable import DayPlanner

struct RelativeDeadlineResolverTests {
    @Test func mondayNextFromThursdayReturnsUpcomingMonday() throws {
        let referenceDate = try fixedDate(year: 2026, month: 6, day: 11) // jeudi

        let deadline = try #require(RelativeDeadlineResolver.deadlineDateString(
            in: "J'ai un entretien technique de type leetcode lundi prochain",
            referenceDate: referenceDate,
            calendar: fixedCalendar
        ))

        #expect(deadline == "2026-06-15")
    }

    @Test func weekdayMatchingIgnoresAccentsAndCase() throws {
        let referenceDate = try fixedDate(year: 2026, month: 6, day: 11) // jeudi

        let deadline = try #require(RelativeDeadlineResolver.deadlineDateString(
            in: "ENTRETIEN MARDI PROCHAIN",
            referenceDate: referenceDate,
            calendar: fixedCalendar
        ))

        #expect(deadline == "2026-06-16")
    }

    @Test func noExplicitWeekdayReturnsNil() throws {
        let referenceDate = try fixedDate(year: 2026, month: 6, day: 11)

        let deadline = RelativeDeadlineResolver.deadlineDateString(
            in: "Je dois préparer un entretien dans un mois",
            referenceDate: referenceDate,
            calendar: fixedCalendar
        )

        #expect(deadline == nil)
    }

    @Test func generatedDeadlineIsOverriddenByExplicitRelativeWeekday() throws {
        let referenceDate = try fixedDate(year: 2026, month: 6, day: 11)
        let extracted = ExtractedGoalDraft(
            rawInput: "J'ai un entretien technique de type leetcode lundi prochain",
            goalTitle: "Entretien LeetCode",
            deadlineDate: "2026-06-12",
            tasks: [
                ExtractedTaskDraft(
                    title: "Faire des exercices LeetCode",
                    typeName: "revision",
                    totalMinutes: 120,
                    sessionMinutes: 60,
                    priority: "high",
                    rationale: "Préparer l'entretien technique."
                )
            ]
        )

        let corrected = extracted.correctingRelativeDeadline(referenceDate: referenceDate, calendar: fixedCalendar)

        #expect(corrected.deadlineDate == "2026-06-15")
    }
}

private var fixedCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    calendar.locale = Locale(identifier: "fr_FR")
    return calendar
}

private func fixedDate(year: Int, month: Int, day: Int) throws -> Date {
    let date = fixedCalendar.date(from: DateComponents(year: year, month: month, day: day))
    return try #require(date)
}
