//
//  NaturalLanguageGoalFormView.swift
//  DayPlanner
//
//  Écran étape 4 : intention naturelle -> prévisualisation éditable -> Goal + PlanTask.
//  Liquid Glass : CTA d'analyse en verre proéminent, résultats animés (spring + blurReplace),
//  contenu en cartes sobres.
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

    private var canAnalyze: Bool {
        !isAnalyzing && !rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                    phraseSection
                    analysisSection

                    if !drafts.isEmpty {
                        proposedGoalSection
                            .transition(.blurReplace.combined(with: .move(edge: .bottom)))
                        proposedTasksSection
                            .transition(.blurReplace.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(Theme.contentPadding)
                .frame(maxWidth: Theme.contentMaxWidth, alignment: .topLeading)
                .animation(.spring(duration: 0.45), value: drafts.isEmpty)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Créer depuis une phrase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") { createGoal() }
                        .buttonStyle(.glassProminent)
                        .disabled(drafts.isEmpty)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("natural-language-create-button")
                }
            }
        }
        .frame(minWidth: 620, minHeight: 700)
    }

    // MARK: - Saisie

    private var phraseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Ton intention", systemImage: "text.quote")
                .font(.headline)

            TextEditor(text: $rawInput)
                .font(.body)
                .frame(minHeight: 90)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(
                    .background,
                    in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous)
                        .strokeBorder(.separator)
                }
                .accessibilityIdentifier("natural-language-input")
                .accessibilityLabel("Phrase naturelle décrivant ton objectif")

            Text("Exemple : Je dois préparer un entretien full-stack dans un mois.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    // MARK: - Analyse

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let availability = extractor.availability()

            if !availability.canExtract {
                Label(availability.userMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !statusMessage.isEmpty {
                Label(statusMessage, systemImage: isAnalyzing ? "hourglass" : "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !errorMessage.isEmpty {
                Label(errorMessage, systemImage: "xmark.octagon.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                analyze()
            } label: {
                HStack(spacing: 8) {
                    if isAnalyzing {
                        ProgressView()
                            .controlSize(.small)
                        Text("Analyse en cours…")
                    } else {
                        Image(systemName: "sparkles")
                            .symbolEffect(.pulse, isActive: isAnalyzing)
                        Text("Analyser avec Apple Intelligence")
                    }
                }
                .frame(minHeight: 22)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(!canAnalyze)
            .accessibilityIdentifier("natural-language-analyze-button")
        }
        .card()
        .animation(.smooth(duration: 0.3), value: statusMessage)
        .animation(.smooth(duration: 0.3), value: errorMessage)
        .animation(.smooth(duration: 0.3), value: isAnalyzing)
    }

    // MARK: - Objectif proposé

    private var proposedGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Objectif proposé", systemImage: "target")
                .font(.headline)

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
            .toggleStyle(.switch)

            if drafts[0].deadline != nil {
                DatePicker(
                    "Deadline",
                    selection: Binding(
                        get: { drafts[0].deadline ?? Date() },
                        set: { drafts[0].deadline = $0 }
                    ),
                    displayedComponents: .date
                )
                .transition(.blurReplace)
            }
        }
        .card()
        .animation(.smooth(duration: 0.3), value: drafts.first?.deadline != nil)
    }

    // MARK: - Tâches proposées

    private var proposedTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tâches proposées", systemImage: "checklist")
                .font(.headline)

            ForEach(drafts.indices, id: \.self) { index in
                ProposedTaskEditor(
                    index: index,
                    draft: $drafts[index]
                )
            }
        }
        .card()
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

    // MARK: - Actions

    private func analyze() {
        isAnalyzing = true
        statusMessage = "Analyse en cours…"
        errorMessage = ""
        withAnimation(.spring(duration: 0.45)) {
            drafts = []
        }

        Task {
            do {
                let extracted = try await extractor.extractGoal(from: rawInput)
                let mappedDrafts = extracted.toManualGoalDrafts()
                await MainActor.run {
                    withAnimation(.spring(duration: 0.45)) {
                        drafts = mappedDrafts
                    }
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

// MARK: - Éditeur de tâche proposée

private struct ProposedTaskEditor: View {
    let index: Int
    @Binding var draft: ManualGoalDraft
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                labeledTextField("Titre", text: $draft.taskTitle)
                labeledTextField("Type", text: $draft.taskTypeName)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    numericField("Durée totale", value: $draft.estimatedHours, unit: "h")
                    numericField("Session", value: $draft.sessionMinutes, unit: "min")
                }

                Picker("Priorité", selection: $draft.priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.displayLabel).tag(priority)
                    }
                }
                .pickerStyle(.segmented)

                labeledTextField("Pourquoi / notes", text: $draft.reasoning, axis: .vertical)
            }
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Tâche \(index + 1)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(draft.taskTitle.isEmpty ? "Sans titre" : draft.taskTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                PriorityBadge(priority: draft.priority)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .disclosureGroupStyle(.automatic)
        .padding(12)
        .background(
            .background,
            in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous)
                .strokeBorder(.separator.opacity(isExpanded ? 1 : 0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth(duration: 0.3), value: isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tâche proposée \(index + 1) : \(draft.taskTitle.isEmpty ? "sans titre" : draft.taskTitle)")
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
