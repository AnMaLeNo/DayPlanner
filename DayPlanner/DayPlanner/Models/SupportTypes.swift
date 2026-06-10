//
//  SupportTypes.swift
//  DayPlanner
//
//  Types support partagés par les modèles : enums de statut, priorité,
//  et la structure de rythme (Rhythm) déduite par le LLM.
//

import Foundation

// MARK: - Statuts

/// Statut d'un objectif.
enum GoalStatus: String, Codable, CaseIterable {
    case active      // en cours
    case completed   // terminé
    case abandoned   // abandonné
}

/// Statut d'une tâche déduite.
enum TaskStatus: String, Codable, CaseIterable {
    case todo        // à faire
    case inProgress  // en cours
    case done        // faite
    case abandoned   // abandonnée
}

/// Statut d'un créneau planifié (Block).
enum BlockStatus: String, Codable, CaseIterable {
    case planned     // planifié
    case done        // fait
    case moved       // déplacé
    case skipped     // sauté
}

/// Priorité d'une tâche (échelle simple, suffisante pour le MVP).
enum Priority: String, Codable, CaseIterable {
    case high        // haute
    case medium      // moyenne
    case low         // basse
}

// MARK: - Rythme

/// Fréquence d'une tâche, déduite par le LLM et exploitable par l'algo de placement.
///
/// Important SwiftData : cette enum n'est PAS persistée directement. `PlanTask` persiste
/// `frequencyKind` + `frequencyValue` (champs primitifs), puis expose un `rhythm` calculé.
/// Ça évite les soucis de persistance transformable/Codable avec l'isolation Swift 6.
enum Frequency: Equatable {
    case once                  // tâche ponctuelle (un seul bloc)
    case daily                 // tous les jours
    case everyNDays(Int)       // tous les N jours (ex. tous les 2 jours)
    case weekly                // une fois par semaine
    case timesPerWeek(Int)     // N fois par semaine

    var storageKind: String {
        switch self {
        case .once: "once"
        case .daily: "daily"
        case .everyNDays: "everyNDays"
        case .weekly: "weekly"
        case .timesPerWeek: "timesPerWeek"
        }
    }

    var storageValue: Int {
        switch self {
        case .once, .daily, .weekly:
            0
        case .everyNDays(let value), .timesPerWeek(let value):
            value
        }
    }

    init(storageKind: String, storageValue: Int) {
        switch storageKind {
        case "daily":
            self = .daily
        case "everyNDays":
            self = .everyNDays(max(1, storageValue))
        case "weekly":
            self = .weekly
        case "timesPerWeek":
            self = .timesPerWeek(max(1, storageValue))
        default:
            self = .once
        }
    }
}

/// Rythme structuré d'une tâche : durée d'une session + fréquence.
///
/// Cette struct reste le modèle métier manipulé par le LLM/l'algo, mais elle n'est pas stockée
/// telle quelle par SwiftData. `PlanTask` la reconstruit depuis des champs primitifs persistés.
struct Rhythm: Equatable {
    /// Durée d'une session, en secondes (TimeInterval).
    var sessionDuration: TimeInterval
    /// Fréquence des sessions.
    var frequency: Frequency

    init(sessionDuration: TimeInterval, frequency: Frequency) {
        self.sessionDuration = sessionDuration
        self.frequency = frequency
    }
}
