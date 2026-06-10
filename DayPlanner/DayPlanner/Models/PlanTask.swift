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
    /// Rythme structuré (durée de session + fréquence), produit par le LLM.
    var rhythm: Rhythm
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
        self.rhythm = rhythm
        self.priority = priority
        self.reasoning = reasoning
        self.status = status
        self.goal = goal
        self.type = type
        self.blocks = blocks
    }
}
