//
//  NaturalLanguageGoalFormView.swift
//  DayPlanner
//
//  Écran étape 4 : intention naturelle -> prévisualisation éditable -> Goal + PlanTask.
//

import SwiftData
import SwiftUI

struct NaturalLanguageGoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var rawInput = ""
    @State private var drafts: [ManualGoalDraft] = []
    @State private var isAnalyzing = false
    @State private var statusMessage = ""
    @State private var errorMessage = ""

    private let extractor = FoundationModelsGoalExtractor()

    var body: some View {
        NavigationStack {
            Form {
                Section("Phrase naturelle") {
                    TextEditor(text: $rawInput)
                        .frame(minHeight: 90)
                        .accessibilityIdentifier("natural-language-input")
                    Text("Exemple : Je dois préparer un entretien full-stack dans un mois.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Analyse Apple Intelligence") {
                    Text(extractor.availability().userMessage)
                        .foregroundStyle(extractor.availability().canExtract ? .secondary : .red)

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundStyle(.secondary)
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }

                    Button {
                        analyze()
                    } label: {
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Label("Analyser", systemImage: "sparkles")
                        }
                    }
                    .disabled(isAnalyzing || rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("natural-language-analyze-button")
                }

                if !drafts.isEmpty {
                    Section("Objectif proposé") {
                        TextField("Titre de l'objectif", text: $drafts[0].goalTitle)
                        DatePicker(
                            "Deadline",
                            selection: Binding(
                                get: { drafts[0].deadline ?? Date() },
                                set: { drafts[0].deadline = $0 }
                            ),
                            displayedComponents: .date
                        )
                        Toggle(
                            "Deadline connue",
                            isOn: Binding(
                                get: { drafts[0].deadline != nil },
                                set: { hasDeadline in
                                    drafts[0].deadline = hasDeadline ? Date() : nil
                                }
                            )
                        )
                    }

                    Section("Tâches proposées") {
                        ForEach(drafts.indices, id: \.self) { index in
                            DisclosureGroup(drafts[index].taskTitle.isEmpty ? "Tâche \(index + 1)" : drafts[index].taskTitle) {
                                TextField("Titre", text: $drafts[index].taskTitle)
                                TextField("Type", text: $drafts[index].taskTypeName)
                                HStack {
                                    Text("Durée totale")
                                    Spacer()
                                    TextField("Heures", value: $drafts[index].estimatedHours, format: .number)
                                        .frame(width: 80)
                                    Text("h")
                                }
                                HStack {
                                    Text("Session")
                                    Spacer()
                                    TextField("Minutes", value: $drafts[index].sessionMinutes, format: .number)
                                        .frame(width: 80)
                                    Text("min")
                                }
                                Picker("Priorité", selection: $drafts[index].priority) {
                                    Text("Basse").tag(Priority.low)
                                    Text("Moyenne").tag(Priority.medium)
                                    Text("Haute").tag(Priority.high)
                                }
                                TextField("Pourquoi / notes", text: $drafts[index].reasoning, axis: .vertical)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Créer depuis une phrase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") { createGoal() }
                        .disabled(drafts.isEmpty)
                        .accessibilityIdentifier("natural-language-create-button")
                }
            }
        }
        .frame(minWidth: 560, minHeight: 680)
    }

    private func analyze() {
        isAnalyzing = true
        statusMessage = "Analyse en cours…"
        errorMessage = ""
        drafts = []

        Task {
            do {
                let extracted = try await extractor.extractGoal(from: rawInput)
                let mappedDrafts = extracted.toManualGoalDrafts()
                await MainActor.run {
                    drafts = mappedDrafts
                    statusMessage = "Analyse terminée : \(mappedDrafts.count) tâche(s) proposée(s)."
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    statusMessage = ""
                    isAnalyzing = false
                }
            }
        }
    }

    private func createGoal() {
        do {
            let goal = try ManualGoalDraft.buildGoal(from: drafts)
            modelContext.insert(goal)
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NaturalLanguageGoalFormView()
        .modelContainer(for: [Goal.self, PlanTask.self, TaskType.self, Block.self, Settings.self], inMemory: true)
}
