//
//  ContentView.swift
//  DayPlanner
//
//  Écran principal : sidebar des objectifs + détail.
//  Liquid Glass : les actions de création vivent dans la toolbar (verre système),
//  le contenu reste sobre et lisible. La création est regroupée dans un menu unique.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @Query private var settings: [Settings]

    @State private var selectedGoal: Goal?
    @State private var isShowingCalendarDebug = false
    @State private var isShowingManualGoalForm = false
    @State private var isShowingNaturalLanguageGoalForm = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        } detail: {
            detail
        }
        .navigationTitle("DayPlanner")
        .toolbar { toolbarContent }
        .task { ensureDefaultSettings() }
        .sheet(isPresented: $isShowingCalendarDebug) {
            CalendarDebugView()
        }
        .sheet(isPresented: $isShowingManualGoalForm) {
            ManualGoalFormView()
        }
        .sheet(isPresented: $isShowingNaturalLanguageGoalForm) {
            NaturalLanguageGoalFormView()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        Group {
            if goals.isEmpty {
                emptySidebar
            } else {
                List(selection: $selectedGoal) {
                    Section("Objectifs") {
                        ForEach(goals) { goal in
                            GoalRow(goal: goal)
                                .tag(goal)
                        }
                        .onDelete(perform: deleteGoals)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .animation(.smooth, value: goals)
    }

    private var emptySidebar: some View {
        ContentUnavailableView {
            Label("Aucun objectif", systemImage: "calendar.badge.plus")
        } description: {
            Text("Décris une intention, DayPlanner la transforme en tâches planifiables.")
        } actions: {
            Button {
                isShowingNaturalLanguageGoalForm = true
            } label: {
                Label("Créer depuis une phrase", systemImage: "sparkles")
            }
            .buttonStyle(.glassProminent)
        }
    }

    // MARK: - Détail

    @ViewBuilder
    private var detail: some View {
        if let selectedGoal {
            GoalDetailView(goal: selectedGoal)
        } else {
            ContentUnavailableView {
                Label("Sélectionne un objectif", systemImage: "sidebar.left")
            } description: {
                Text("Choisis un objectif dans la barre latérale pour voir ses tâches.")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    isShowingNaturalLanguageGoalForm = true
                } label: {
                    Label("Depuis une phrase…", systemImage: "sparkles")
                }
                .keyboardShortcut("n", modifiers: [.command])
                .accessibilityIdentifier("natural-language-goal-create-button")

                Button {
                    isShowingManualGoalForm = true
                } label: {
                    Label("Objectif manuel…", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .accessibilityIdentifier("manual-goal-create-button")

                Divider()

                Button(action: addSampleGoal) {
                    Label("Objectif de test", systemImage: "plus")
                }
            } label: {
                Label("Créer", systemImage: "plus")
            }
            .buttonStyle(.glassProminent)
            .accessibilityIdentifier("create-goal-menu")
        }

        ToolbarItem(placement: .secondaryAction) {
            Button {
                isShowingCalendarDebug = true
            } label: {
                Label("Calendrier", systemImage: "calendar")
            }
            .help("Vérifier l'accès calendrier et les créneaux libres")
        }
    }

    // MARK: - Données

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
        selectedGoal = goal
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
            let goal = goals[index]
            if goal == selectedGoal {
                selectedGoal = nil
            }
            modelContext.delete(goal)
        }
    }
}

// MARK: - Ligne d'objectif (sidebar)

private struct GoalRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.title)
                .font(.headline)
                .lineLimit(1)

            if let deadline = goal.deadline {
                Label {
                    Text(deadline, format: .dateTime.day().month().year())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text(goal.rawInput)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Détail d'un objectif

private struct GoalDetailView: View {
    let goal: Goal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                header
                tasksSection
            }
            .padding(Theme.contentPadding)
            .frame(maxWidth: Theme.contentMaxWidth, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(goal.title)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(goal.rawInput)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                InfoChip(systemImage: "circle.dashed", text: goal.status.rawValue)

                if let deadline = goal.deadline {
                    InfoChip(
                        systemImage: "calendar",
                        text: deadline.formatted(date: .abbreviated, time: .omitted)
                    )
                } else {
                    InfoChip(systemImage: "calendar.badge.minus", text: "Sans deadline")
                }
            }
        }
        .card()
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tâches déduites")
                .font(.title3.weight(.semibold))

            if goal.tasks.isEmpty {
                ContentUnavailableView(
                    "Aucune tâche",
                    systemImage: "checklist",
                    description: Text("Cet objectif n'a pas encore de tâches associées.")
                )
                .card()
            } else {
                ForEach(goal.tasks) { task in
                    TaskCard(task: task)
                }
            }
        }
    }
}

private struct TaskCard: View {
    let task: PlanTask

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(task.title)
                    .font(.headline)
                Spacer(minLength: 8)
                PriorityBadge(priority: task.priority)
            }

            if !task.reasoning.isEmpty {
                Text(task.reasoning)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                if let typeName = task.type?.name, !typeName.isEmpty {
                    InfoChip(systemImage: "tag", text: typeName)
                }
                InfoChip(systemImage: "square.stack.3d.up", text: "\(task.blocks.count) bloc(s)")
            }
        }
        .card()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Goal.self, PlanTask.self, Block.self, TaskType.self, Settings.self], inMemory: true)
}
