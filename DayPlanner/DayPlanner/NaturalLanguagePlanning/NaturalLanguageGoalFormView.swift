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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    phraseSection
                    analysisSection

                    if !drafts.isEmpty {
                        proposedGoalSection
                        proposedTasksSection
                    }
                }
                .padding(24)
                .frame(maxWidth: 760, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .frame(minWidth: 620, minHeight: 700)
    }

    private var phraseSection: some View {
        GroupBox("Phrase naturelle") {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $rawInput)
                    .frame(minHeight: 90)
                    .accessibilityIdentifier("natural-language-input")
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    }

                Text("Exemple : Je dois préparer un entretien full-stack dans un mois.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var analysisSection: some View {
        GroupBox("Analyse Apple Intelligence") {
            VStack(alignment: .leading, spacing: 10) {
                Text(extractor.availability().userMessage)
                    .foregroundStyle(extractor.availability().canExtract ? Color.secondary : Color.red)
                    .fixedSize(horizontal: false, vertical: true)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var proposedGoalSection: some View {
        GroupBox("Objectif proposé") {
            VStack(alignment: .leading, spacing: 12) {
                labeledTextField("Titre de l'objectif", text: $drafts[0].goalTitle)

                Toggle(
                    "Deadline connue",
                    isOn: Binding(
                        get: { drafts[0].deadline != nil },
                        set: { hasDeadline in
                            drafts[0].deadline = hasDeadline ? Date() : nil
                        }
                    )
                )

                if drafts[0].deadline != nil {
                    DatePicker(
                        "Deadline",
                        selection: Binding(
                            get: { drafts[0].deadline ?? Date() },
                            set: { drafts[0].deadline = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var proposedTasksSection: some View {
        GroupBox("Tâches proposées") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(drafts.indices, id: \.self) { index in
                    ProposedTaskEditor(
                        index: index,
                        draft: $drafts[index]
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeledTextField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
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

private struct ProposedTaskEditor: View {
    let index: Int
    @Binding var draft: ManualGoalDraft

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                labeledTextField("Titre", text: $draft.taskTitle)
                labeledTextField("Type", text: $draft.taskTypeName)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    numericField("Durée totale", value: $draft.estimatedHours, unit: "h")
                    numericField("Session", value: $draft.sessionMinutes, unit: "min")
                }

                Picker("Priorité", selection: $draft.priority) {
                    Text("Basse").tag(Priority.low)
                    Text("Moyenne").tag(Priority.medium)
                    Text("Haute").tag(Priority.high)
                }
                .pickerStyle(.segmented)

                labeledTextField("Pourquoi / notes", text: $draft.reasoning, axis: .vertical)
            }
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Tâche \(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(draft.taskTitle.isEmpty ? "Sans titre" : draft.taskTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.2))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeledTextField(
        _ label: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, text: text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(axis == .vertical ? 2...5 : 1...1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func numericField(
        _ label: String,
        value: Binding<Double>,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                TextField(label, value: value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NaturalLanguageGoalFormView()
        .modelContainer(for: [Goal.self, PlanTask.self, TaskType.self, Block.self, Settings.self], inMemory: true)
}
