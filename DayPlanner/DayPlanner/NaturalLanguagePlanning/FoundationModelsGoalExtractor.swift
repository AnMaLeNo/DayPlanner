//
//  FoundationModelsGoalExtractor.swift
//  DayPlanner
//
//  Service minimal d'extraction objectif + tâches via FoundationModels.
//  Il ne persiste rien : il retourne un draft éditable par l'utilisateur.
//

import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
protocol GoalExtractionProviding {
    func availability() -> GoalExtractionAvailability
    func extractGoal(from rawInput: String) async throws -> ExtractedGoalDraft
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
struct FoundationModelsGoalExtractor: GoalExtractionProviding {
    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    func availability() -> GoalExtractionAvailability {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason.userMessage)
        }
    }

    func extractGoal(from rawInput: String) async throws -> ExtractedGoalDraft {
        let cleanedInput = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedInput.isEmpty else { throw GoalExtractionError.emptyInput }

        let currentAvailability = availability()
        guard currentAvailability.canExtract else {
            throw GoalExtractionError.unavailable(currentAvailability.userMessage)
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            Tu transformes une intention utilisateur en objectif et tâches de planning.
            Réponds en français avec des titres courts et concrets.
            Ne crée pas de calendrier et ne crée pas de blocs horaires.
            Si une deadline est ambiguë ou absente, laisse deadlineDate vide.
            Propose entre 1 et 5 tâches concrètes.
            Utilise priority uniquement parmi low, medium, high.
            Utilise typeName en minuscules, par exemple frontend, backend, design, admin, revision, autre.
            Donne des durées réalistes mais prudentes.
            Si l'utilisateur donne une deadline relative, calcule-la par rapport à la date de référence fournie dans le prompt.
            Ne choisis jamais une date passée sauf si l'utilisateur la donne explicitement.
            """
        )

        let response = try await session.respond(
            to: prompt(for: cleanedInput),
            generating: GeneratedGoalDraft.self
        )

        return response.content
            .extracted(rawInput: cleanedInput)
            .correctingRelativeDeadline()
    }

    private func prompt(for cleanedInput: String) -> String {
        let currentDate = Self.referenceDateFormatter.string(from: Date())
        return """
        Date de référence: \(currentDate)
        Demande utilisateur: \(cleanedInput)
        """
    }

    private static let referenceDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
private extension SystemLanguageModel.Availability.UnavailableReason {
    var userMessage: String {
        switch self {
        case .deviceNotEligible:
            "Cet appareil n'est pas éligible à Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence n'est pas activé sur cet appareil."
        case .modelNotReady:
            "Le modèle Apple Intelligence n'est pas encore prêt. Réessaie plus tard."
        @unknown default:
            "Foundation Models n'est pas disponible sur cet appareil."
        }
    }
}
