//
//  ContentView.swift
//  DayPlanner
//
//  Vue de démarrage temporaire pour valider l'étape 1 :
//  - SwiftData configuré avec les vrais modèles
//  - création / lecture / suppression de Goal → PlanTask → Block
//  - Settings par défaut créé au premier lancement
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @Query private var settings: [Settings]

    var body: some View {
        NavigationSplitView {
            List {
                Section("Objectifs") {
                    if goals.isEmpty {
                        ContentUnavailableView(
                            "Aucun objectif",
                            systemImage: "calendar.badge.plus",
                            description: Text("Ajoute un objectif de test pour valider SwiftData.")
                        )
                    } else {
                        ForEach(goals) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .font(.headline)
                                    Text(goal.rawInput)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .onDelete(perform: deleteGoals)
                    }
                }
            }
            .navigationTitle("DayPlanner")
            .toolbar {
                ToolbarItem {
                    Button(action: addSampleGoal) {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Sélectionne un objectif")
                .foregroundStyle(.secondary)
        }
        .task {
            ensureDefaultSettings()
        }
    }

    private func ensureDefaultSettings() {
        guard settings.isEmpty else { return }
        modelContext.insert(Settings())
    }

    private func addSampleGoal() {
        let leetcodeType = findOrCreateTaskType(named: "leetcode")

        let goal = Goal(
            rawInput: "Je dois préparer un entretien full-stack dans un mois.",
            title: "Préparer entretien full-stack",
            deadline: Calendar.current.date(byAdding: .month, value: 1, to: .now)
        )

        let task = PlanTask(
            title: "Faire du LeetCode",
            estimatedDuration: 8 * 60 * 60,
            rhythm: Rhythm(sessionDuration: 60 * 60, frequency: .everyNDays(2)),
            priority: .high,
            reasoning: "Les exercices d'algorithmique sont fréquents en entretien technique full-stack.",
            goal: goal,
            type: leetcodeType
        )

        let block = Block(
            start: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
            end: Calendar.current.date(byAdding: .day, value: 1, to: .now.addingTimeInterval(60 * 60)) ?? .now.addingTimeInterval(60 * 60),
            task: task
        )

        task.blocks.append(block)
        goal.tasks.append(task)

        modelContext.insert(goal)
    }

    private func findOrCreateTaskType(named name: String) -> TaskType {
        let descriptor = FetchDescriptor<TaskType>(
            predicate: #Predicate { $0.name == name }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let type = TaskType(name: name)
        modelContext.insert(type)
        return type
    }

    private func deleteGoals(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(goals[index])
        }
    }
}

private struct GoalDetailView: View {
    let goal: Goal

    var body: some View {
        List {
            Section("Objectif") {
                LabeledContent("Titre", value: goal.title)
                LabeledContent("Phrase brute", value: goal.rawInput)
                LabeledContent("Statut", value: goal.status.rawValue)
                if let deadline = goal.deadline {
                    LabeledContent("Deadline") {
                        Text(deadline, format: .dateTime.day().month().year())
                    }
                } else {
                    LabeledContent("Deadline", value: "Aucune")
                }
            }

            Section("Tâches déduites") {
                if goal.tasks.isEmpty {
                    Text("Aucune tâche")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(goal.tasks) { task in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title)
                                .font(.headline)
                            Text(task.reasoning)
                                .foregroundStyle(.secondary)
                            Text("Priorité : \(task.priority.rawValue) · Type : \(task.type?.name ?? "aucun") · Blocs : \(task.blocks.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(goal.title)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Goal.self, PlanTask.self, Block.self, TaskType.self, Settings.self], inMemory: true)
}
