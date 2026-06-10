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
enum Frequency: Codable, Equatable {
    case once                  // tâche ponctuelle (un seul bloc)
    case daily                 // tous les jours
    case everyNDays(Int)       // tous les N jours (ex. tous les 2 jours)
    case weekly                // une fois par semaine
    case timesPerWeek(Int)     // N fois par semaine
}

/// Rythme structuré d'une tâche : durée d'une session + fréquence.
/// Le LLM produit cette structure (PAS du texte libre) pour que l'algo
/// puisse calculer combien de blocs placer et à quels intervalles.
struct Rhythm: Codable, Equatable {
    /// Durée d'une session, en secondes (TimeInterval).
    var sessionDuration: TimeInterval
    /// Fréquence des sessions.
    var frequency: Frequency

    init(sessionDuration: TimeInterval, frequency: Frequency) {
        self.sessionDuration = sessionDuration
        self.frequency = frequency
    }
}
