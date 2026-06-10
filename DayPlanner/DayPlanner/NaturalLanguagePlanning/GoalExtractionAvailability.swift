//
//  GoalExtractionAvailability.swift
//  DayPlanner
//
//  État public de disponibilité de l'extraction Apple Intelligence.
//

import Foundation

enum GoalExtractionAvailability: Equatable {
    case available
    case unavailable(String)

    var canExtract: Bool {
        switch self {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }

    var userMessage: String {
        switch self {
        case .available:
            return "Apple Intelligence est disponible."
        case .unavailable(let reason):
            let cleaned = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? "Foundation Models n'est pas disponible sur cet appareil." : cleaned
        }
    }
}

enum GoalExtractionError: LocalizedError {
    case unavailable(String)
    case emptyInput

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            GoalExtractionAvailability.unavailable(reason).userMessage
        case .emptyInput:
            "Écris d'abord une phrase à analyser."
        }
    }
}
