//
//  CalendarDebugView.swift
//  DayPlanner
//
//  Vue temporaire de validation EventKit (étape 2).
//  Elle permet de vérifier : permission calendrier, événements lus,
//  et créneaux libres calculés à partir des Settings.
//

import SwiftData
import SwiftUI

struct CalendarDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [Settings]
    @StateObject private var calendarService = CalendarService()
    @State private var freeSlots: [FreeSlot] = []
    @State private var isLoading = false

    private var activeSettings: Settings {
        settings.first ?? Settings()
    }

    var body: some View {
        NavigationStack {
            List {
                permissionSection
                actionsSection
                eventsSection
                freeSlotsSection
                if let errorMessage = calendarService.errorMessage {
                    Section("Erreur") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Debug calendrier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private var permissionSection: some View {
        Section("Permission") {
            LabeledContent("Statut", value: calendarService.accessState.label)
            Text("DayPlanner lit votre calendrier pour identifier les créneaux occupés. Les événements ne sont pas copiés dans SwiftData.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button("Demander l'accès calendrier") {
                Task { await calendarService.requestAccess() }
            }

            Button("Lire aujourd'hui") {
                Task { await loadToday() }
            }
            .disabled(!calendarService.accessState.canReadEvents || isLoading)
        }
    }

    private var eventsSection: some View {
        Section("Événements aujourd'hui (\(calendarService.events.count))") {
            if calendarService.events.isEmpty {
                Text("Aucun événement chargé.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(calendarService.events) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                        Text("\(formatTime(event.start)) – \(formatTime(event.end)) · \(event.calendarTitle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var freeSlotsSection: some View {
        Section("Créneaux libres calculés (\(freeSlots.count))") {
            if freeSlots.isEmpty {
                Text("Aucun créneau libre calculé.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(freeSlots) { slot in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(formatTime(slot.start)) – \(formatTime(slot.end))")
                            .font(.headline)
                        Text(formatDuration(slot.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @MainActor
    private func loadToday() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(24 * 60 * 60)
        let range = DateInterval(start: start, end: end)

        let loadedEvents = await calendarService.loadEvents(in: range)
        freeSlots = FreeSlotCalculator.freeSlots(
            events: loadedEvents,
            in: range,
            rules: SchedulingRules(settings: activeSettings),
            calendar: calendar
        )
    }

    private func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours) h \(remainingMinutes) min"
        }
        return "\(remainingMinutes) min"
    }
}

#Preview {
    CalendarDebugView()
        .modelContainer(for: [Goal.self, PlanTask.self, Block.self, TaskType.self, Settings.self], inMemory: true)
}
