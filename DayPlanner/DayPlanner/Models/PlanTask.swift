//
//  PlanTask.swift
//  DayPlanner
//
//  Tâche DÉDUITE par le LLM à partir d'un Goal.
//  Nommée `PlanTask` (et non `Task`) pour éviter le conflit avec Swift.Task (async/await).
//  Niveau 2 du modèle : Goal → PlanTask → Block.
//

import Foundation
import SwiftData

@Model
final class PlanTask {
    /// Identifiant unique.
    var id: UUID
    /// Intitulé de la tâche (ex. « réviser le backend »).
    var title: String
    /// Durée totale estimée, en secondes (TimeInterval).
    var estimatedDuration: TimeInterval
    /// Durée d'une session, persistée en secondes (TimeInterval).
    var rhythmSessionDuration: TimeInterval
    /// Type de fréquence persisté sous forme primitive (ex. "everyNDays").
    var frequencyKind: String
    /// Valeur associée à la fréquence si nécessaire (ex. 2 pour tous les 2 jours).
    var frequencyValue: Int
    /// Priorité (haute / moyenne / basse).
    var priority: Priority
    /// Explication du LLM : POURQUOI cette tâche (le « pourquoi » du produit).
    var reasoning: String
    /// Statut de la tâche.
    var status: TaskStatus

    /// Objectif parent (relation inverse de Goal.tasks).
    var goal: Goal?

    /// Catégorie de la tâche (vocabulaire dynamique). Base des préférences V2.
    var type: TaskType?

    /// Créneaux concrets placés par l'algo. Une tâche récurrente génère N Block.
    /// Supprimer une PlanTask supprime ses Block en cascade.
    @Relationship(deleteRule: .cascade, inverse: \Block.task)
    var blocks: [Block]

    /// Rythme métier exposé au reste de l'app.
    /// SwiftData persiste les champs primitifs ci-dessus, pas la struct `Rhythm` directement.
    var rhythm: Rhythm {
        get {
            Rhythm(
                sessionDuration: rhythmSessionDuration,
                frequency: Frequency(storageKind: frequencyKind, storageValue: frequencyValue)
            )
        }
        set {
            rhythmSessionDuration = newValue.sessionDuration
            frequencyKind = newValue.frequency.storageKind
            frequencyValue = newValue.frequency.storageValue
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        estimatedDuration: TimeInterval,
        rhythm: Rhythm,
        priority: Priority = .medium,
        reasoning: String = "",
        status: TaskStatus = .todo,
        goal: Goal? = nil,
        type: TaskType? = nil,
        blocks: [Block] = []
    ) {
        self.id = id
        self.title = title
        self.estimatedDuration = estimatedDuration
        self.rhythmSessionDuration = rhythm.sessionDuration
        self.frequencyKind = rhythm.frequency.storageKind
        self.frequencyValue = rhythm.frequency.storageValue
        self.priority = priority
        self.reasoning = reasoning
        self.status = status
        self.goal = goal
        self.type = type
        self.blocks = blocks
    }
}
