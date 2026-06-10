//
//  TaskType.swift
//  DayPlanner
//
//  Catégorie de tâche (vocabulaire dynamique / taxonomie évolutive).
//  Le LLM réutilise un type existant si possible, sinon il en crée un nouveau.
//  Base du système de préférences en V2.
//

import Foundation
import SwiftData

@Model
final class TaskType {
    /// Identifiant unique.
    var id: UUID
    /// Nom de catégorie (ex. « leetcode », « révision », « achat »).
    var name: String

    /// Tâches qui référencent ce type.
    @Relationship(inverse: \PlanTask.type)
    var tasks: [PlanTask]

    init(
        id: UUID = UUID(),
        name: String,
        tasks: [PlanTask] = []
    ) {
        self.id = id
        self.name = name
        self.tasks = tasks
    }
}
