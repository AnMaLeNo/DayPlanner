//
//  Goal.swift
//  DayPlanner
//
//  Objectif formulé par l'utilisateur (à la voix ou au texte).
//  Niveau 1 du modèle : Goal → PlanTask → Block.
//

import Foundation
import SwiftData

@Model
final class Goal {
    /// Identifiant unique.
    var id: UUID
    /// La phrase brute telle que dite/écrite par l'utilisateur (utile pour re-déduire).
    var rawInput: String
    /// Titre court généré par le LLM à partir de `rawInput`.
    var title: String
    /// Échéance — optionnelle (ex. « apprendre la guitare » n'en a pas).
    var deadline: Date?
    /// Date de création.
    var createdAt: Date
    /// Statut de l'objectif.
    var status: GoalStatus

    /// Tâches déduites par le LLM pour atteindre cet objectif.
    /// Supprimer un Goal supprime ses PlanTask en cascade (pas d'orphelins).
    @Relationship(deleteRule: .cascade, inverse: \PlanTask.goal)
    var tasks: [PlanTask]

    init(
        id: UUID = UUID(),
        rawInput: String,
        title: String,
        deadline: Date? = nil,
        createdAt: Date = .now,
        status: GoalStatus = .active,
        tasks: [PlanTask] = []
    ) {
        self.id = id
        self.rawInput = rawInput
        self.title = title
        self.deadline = deadline
        self.createdAt = createdAt
        self.status = status
        self.tasks = tasks
    }
}
