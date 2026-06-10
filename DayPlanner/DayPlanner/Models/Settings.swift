//
//  Settings.swift
//  DayPlanner
//
//  Contraintes configurables du moteur de placement.
//  Une instance par défaut est créée au premier lancement.
//

import Foundation
import SwiftData

@Model
final class Settings {
    /// Identifiant unique.
    var id: UUID

    /// Heure de début de travail (minutes depuis minuit). Défaut : 09:00 = 540.
    var workStartMinutes: Int
    /// Heure de fin de travail (minutes depuis minuit). Défaut : 19:00 = 1140.
    var workEndMinutes: Int

    /// Durée minimale d'un bloc, en secondes. Défaut : 25 min.
    var minBlockDuration: TimeInterval
    /// Durée maximale d'un bloc, en secondes. Défaut : 2 h.
    var maxBlockDuration: TimeInterval
    /// Pause entre deux blocs, en secondes. Défaut : 10 min.
    var breakDuration: TimeInterval
    /// Maximum d'heures focus par jour, en secondes. Défaut : 6 h.
    var maxFocusDurationPerDay: TimeInterval

    /// Jours travaillés, encodés avec Calendar weekday (1 = dimanche, 2 = lundi, ..., 7 = samedi).
    /// Défaut : lundi → vendredi = [2, 3, 4, 5, 6].
    var workDays: [Int]

    init(
        id: UUID = UUID(),
        workStartMinutes: Int = 9 * 60,
        workEndMinutes: Int = 19 * 60,
        minBlockDuration: TimeInterval = 25 * 60,
        maxBlockDuration: TimeInterval = 2 * 60 * 60,
        breakDuration: TimeInterval = 10 * 60,
        maxFocusDurationPerDay: TimeInterval = 6 * 60 * 60,
        workDays: [Int] = [2, 3, 4, 5, 6]
    ) {
        self.id = id
        self.workStartMinutes = workStartMinutes
        self.workEndMinutes = workEndMinutes
        self.minBlockDuration = minBlockDuration
        self.maxBlockDuration = maxBlockDuration
        self.breakDuration = breakDuration
        self.maxFocusDurationPerDay = maxFocusDurationPerDay
        self.workDays = workDays
    }
}
