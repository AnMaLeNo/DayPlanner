//
//  ManualGoalFormView.swift
//  DayPlanner
//
//  Écran temporaire mais utilisable de création manuelle d'un objectif + première tâche.
//  Le futur module Foundation Models remplira le même modèle SwiftData automatiquement.
//

import SwiftData
import SwiftUI

struct ManualGoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var rawInput = ""
    @State private var goalTitle = ""
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var taskTitle = ""
    @State private var taskTypeName = ""
    @State private var estimatedHours = 1.0
    @State private var sessionMinutes = 60.0
    @State private var priority: Priority = .medium
    @State private var reasoning = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Objectif") {
                    TextField("Phrase brute / intention", text: $rawInput, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Titre de l'objectif", text: $goalTitle)

                    Toggle("Ajouter une deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                    }
                }

                Section("Première tâche") {
                    TextField("Titre de la tâche", text: $taskTitle)
                    TextField("Type de tâche (optionnel)", text: $taskTypeName)

                    TextField("Durée totale estimée (heures)", value: $estimatedHours, format: .number)
                    TextField("Durée d'une session (minutes)", value: $sessionMinutes, format: .number)

                    Picker("Priorité", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.manualFormLabel).tag(priority)
                        }
                    }
                }

                Section("Pourquoi / notes") {
                    TextField("Pourquoi cette tâche est utile ?", text: $reasoning, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let errorMessage {
                    Section("Erreur") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Nouvel objectif")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer", action: createGoal)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 620)
    }

    private func createGoal() {
        errorMessage = nil

        let draft = ManualGoalDraft(
            rawInput: rawInput,
            goalTitle: goalTitle,
            deadline: hasDeadline ? deadline : nil,
            taskTitle: taskTitle,
            taskTypeName: taskTypeName,
            estimatedHours: estimatedHours,
            sessionMinutes: sessionMinutes,
            priority: priority,
            reasoning: reasoning
        )

        do {
            let result = try draft.buildGoal()
            reuseExistingTaskTypeIfNeeded(for: result.task)
            modelContext.insert(result.goal)
            dismiss()
        } catch let error as ManualGoalDraft.ValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Impossible de créer l'objectif."
        }
    }

    private func reuseExistingTaskTypeIfNeeded(for task: PlanTask) {
        guard let newType = task.type else { return }

        let name = newType.name
        let descriptor = FetchDescriptor<TaskType>(
            predicate: #Predicate { $0.name == name }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            task.type = existing
        } else {
            modelContext.insert(newType)
        }
    }
}

private extension Priority {
    var manualFormLabel: String {
        switch self {
        case .high: "Haute"
        case .medium: "Moyenne"
        case .low: "Basse"
        }
    }
}

private extension ManualGoalDraft.ValidationError {
    var userMessage: String {
        switch self {
        case .blankGoalTitle:
            "Le titre de l'objectif est obligatoire."
        case .blankTaskTitle:
            "Le titre de la tâche est obligatoire."
        case .nonPositiveEstimatedDuration:
            "La durée totale estimée doit être supérieure à 0."
        case .nonPositiveSessionDuration:
            "La durée d'une session doit être supérieure à 0."
        }
    }
}

#Preview {
    ManualGoalFormView()
        .modelContainer(for: [Goal.self, PlanTask.self, Block.self, TaskType.self, Settings.self], inMemory: true)
}
