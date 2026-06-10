//
//  FreeSlotCalculatorTests.swift
//  DayPlannerTests
//
//  Tests de l'étape 2 : calcul pur des créneaux libres.
//  EventKit n'est pas utilisé ici : ces tests valident seulement l'algo
//  qui retire les événements occupés des heures de travail.
//

import Foundation
import Testing
@testable import DayPlanner

struct FreeSlotCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test func emptyWorkdayReturnsSingleWorkWindow() {
        let day = makeDate(2026, 6, 8, 0, 0) // lundi
        let range = DateInterval(start: day, end: makeDate(2026, 6, 9, 0, 0))
        let rules = SchedulingRules(
            workStartMinutes: 9 * 60,
            workEndMinutes: 19 * 60,
            minBlockDuration: 25 * 60,
            workDays: [2, 3, 4, 5, 6]
        )

        let slots = FreeSlotCalculator.freeSlots(events: [], in: range, rules: rules, calendar: calendar)

        #expect(slots == [
            FreeSlot(start: makeDate(2026, 6, 8, 9, 0), end: makeDate(2026, 6, 8, 19, 0))
        ])
    }

    @Test func eventInMiddleSplitsTheWorkWindow() {
        let day = makeDate(2026, 6, 8, 0, 0) // lundi
        let range = DateInterval(start: day, end: makeDate(2026, 6, 9, 0, 0))
        let rules = SchedulingRules(
            workStartMinutes: 9 * 60,
            workEndMinutes: 19 * 60,
            minBlockDuration: 25 * 60,
            workDays: [2, 3, 4, 5, 6]
        )
        let events = [
            CalendarEvent(
                id: "meeting",
                title: "Réunion",
                start: makeDate(2026, 6, 8, 10, 0),
                end: makeDate(2026, 6, 8, 11, 0),
                calendarTitle: "Travail"
            )
        ]

        let slots = FreeSlotCalculator.freeSlots(events: events, in: range, rules: rules, calendar: calendar)

        #expect(slots == [
            FreeSlot(start: makeDate(2026, 6, 8, 9, 0), end: makeDate(2026, 6, 8, 10, 0)),
            FreeSlot(start: makeDate(2026, 6, 8, 11, 0), end: makeDate(2026, 6, 8, 19, 0))
        ])
    }

    @Test func overlappingEventsAreMergedBeforeSubtracting() {
        let day = makeDate(2026, 6, 8, 0, 0) // lundi
        let range = DateInterval(start: day, end: makeDate(2026, 6, 9, 0, 0))
        let rules = SchedulingRules(
            workStartMinutes: 9 * 60,
            workEndMinutes: 19 * 60,
            minBlockDuration: 25 * 60,
            workDays: [2, 3, 4, 5, 6]
        )
        let events = [
            CalendarEvent(id: "a", title: "A", start: makeDate(2026, 6, 8, 10, 0), end: makeDate(2026, 6, 8, 11, 0), calendarTitle: "Travail"),
            CalendarEvent(id: "b", title: "B", start: makeDate(2026, 6, 8, 10, 30), end: makeDate(2026, 6, 8, 12, 0), calendarTitle: "Travail")
        ]

        let slots = FreeSlotCalculator.freeSlots(events: events, in: range, rules: rules, calendar: calendar)

        #expect(slots == [
            FreeSlot(start: makeDate(2026, 6, 8, 9, 0), end: makeDate(2026, 6, 8, 10, 0)),
            FreeSlot(start: makeDate(2026, 6, 8, 12, 0), end: makeDate(2026, 6, 8, 19, 0))
        ])
    }

    @Test func nonWorkdayReturnsNoSlots() {
        let day = makeDate(2026, 6, 7, 0, 0) // dimanche
        let range = DateInterval(start: day, end: makeDate(2026, 6, 8, 0, 0))
        let rules = SchedulingRules(
            workStartMinutes: 9 * 60,
            workEndMinutes: 19 * 60,
            minBlockDuration: 25 * 60,
            workDays: [2, 3, 4, 5, 6]
        )

        let slots = FreeSlotCalculator.freeSlots(events: [], in: range, rules: rules, calendar: calendar)

        #expect(slots.isEmpty)
    }

    @Test func slotsShorterThanMinimumDurationAreFilteredOut() {
        let day = makeDate(2026, 6, 8, 0, 0) // lundi
        let range = DateInterval(start: day, end: makeDate(2026, 6, 9, 0, 0))
        let rules = SchedulingRules(
            workStartMinutes: 9 * 60,
            workEndMinutes: 19 * 60,
            minBlockDuration: 25 * 60,
            workDays: [2, 3, 4, 5, 6]
        )
        let events = [
            CalendarEvent(id: "a", title: "A", start: makeDate(2026, 6, 8, 9, 20), end: makeDate(2026, 6, 8, 19, 0), calendarTitle: "Travail")
        ]

        let slots = FreeSlotCalculator.freeSlots(events: events, in: range, rules: rules, calendar: calendar)

        #expect(slots.isEmpty)
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date!
    }
}
