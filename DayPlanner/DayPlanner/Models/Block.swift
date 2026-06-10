//
//  Block.swift
//  DayPlanner
//
//  Créneau planifié, PLACÉ par l'algo d'ordonnancement dans un trou réel du calendrier.
//  Niveau 3 du modèle : Goal → PlanTask → Block.
//  C'est ce que l'utilisateur voit et déplace dans le planning.
//

import Foundation
import SwiftData

@Model
final class Block {
    /// Identifiant unique.
    var id: UUID
    /// Début exact du créneau (posé par l'algo, sans conflit).
    var start: Date
    /// Fin exacte du créneau.
    var end: Date
    /// Statut du créneau.
    var status: BlockStatus

    /// Tâche parente (relation inverse de PlanTask.blocks).
    var task: PlanTask?

    init(
        id: UUID = UUID(),
        start: Date,
        end: Date,
        status: BlockStatus = .planned,
        task: PlanTask? = nil
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.status = status
        self.task = task
    }
}
