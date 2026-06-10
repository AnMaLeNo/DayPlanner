//
//  CalendarTypes.swift
//  DayPlanner
//
//  Types simples utilisés entre EventKit, le calcul de créneaux libres,
//  et plus tard le moteur de placement.
//

import Foundation

/// Représentation interne minimale d'un événement calendrier.
///
/// On évite de faire fuiter `EKEvent` hors de `CalendarService` : EventKit reste
/// une frontière externe, et le calcul de créneaux libres reste testable sans calendrier réel.
struct CalendarEvent: Equatable, Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let calendarTitle: String
}

/// Créneau libre exploitable par l'algorithme de placement.
struct FreeSlot: Equatable, Identifiable {
    let id: String
    let start: Date
    let end: Date

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
        self.id = "\(start.timeIntervalSince1970)-\(end.timeIntervalSince1970)"
    }

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

/// Snapshot non-SwiftData des règles nécessaires au calcul.
///
/// Le calculateur reste indépendant de SwiftData : l'UI peut construire ce snapshot
/// depuis `Settings`, mais les tests peuvent l'instancier directement.
struct SchedulingRules: Equatable {
    var workStartMinutes: Int
    var workEndMinutes: Int
    var minBlockDuration: TimeInterval
    var workDays: [Int]

    init(
        workStartMinutes: Int,
        workEndMinutes: Int,
        minBlockDuration: TimeInterval,
        workDays: [Int]
    ) {
        self.workStartMinutes = workStartMinutes
        self.workEndMinutes = workEndMinutes
        self.minBlockDuration = minBlockDuration
        self.workDays = workDays
    }

    init(settings: Settings) {
        self.init(
            workStartMinutes: settings.workStartMinutes,
            workEndMinutes: settings.workEndMinutes,
            minBlockDuration: settings.minBlockDuration,
            workDays: settings.workDays
        )
    }
}
