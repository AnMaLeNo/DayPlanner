//
//  CalendarService.swift
//  DayPlanner
//
//  Frontière EventKit : permissions + lecture des événements.
//  Le reste de l'app manipule `CalendarEvent`, jamais `EKEvent`.
//

import Combine
import EventKit
import Foundation

@MainActor
final class CalendarService: ObservableObject {
    @Published private(set) var accessState: CalendarAccessState
    @Published private(set) var events: [CalendarEvent] = []
    @Published private(set) var errorMessage: String?

    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
        self.accessState = CalendarAccessState(status: EKEventStore.authorizationStatus(for: .event))
    }

    @discardableResult
    func requestAccess() async -> Bool {
        errorMessage = nil

        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            accessState = CalendarAccessState(status: EKEventStore.authorizationStatus(for: .event))
            return granted
        } catch {
            accessState = CalendarAccessState(status: EKEventStore.authorizationStatus(for: .event))
            errorMessage = error.localizedDescription
            return false
        }
    }

    func refreshAccessState() {
        accessState = CalendarAccessState(status: EKEventStore.authorizationStatus(for: .event))
    }

    func loadEvents(in range: DateInterval) async -> [CalendarEvent] {
        errorMessage = nil
        refreshAccessState()

        guard accessState == .fullAccess else {
            events = []
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: range.start,
            end: range.end,
            calendars: nil
        )

        let loadedEvents = eventStore.events(matching: predicate)
            .filter { $0.startDate < $0.endDate }
            .map { event in
                CalendarEvent(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "Sans titre",
                    start: event.startDate,
                    end: event.endDate,
                    calendarTitle: event.calendar.title
                )
            }
            .sorted { $0.start < $1.start }

        events = loadedEvents
        return loadedEvents
    }
}

enum CalendarAccessState: Equatable {
    case notDetermined
    case fullAccess
    case writeOnly
    case denied
    case restricted
    case unknown(String)

    init(status: EKAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .fullAccess:
            self = .fullAccess
        case .writeOnly:
            self = .writeOnly
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        @unknown default:
            self = .unknown("\(status.rawValue)")
        }
    }

    var label: String {
        switch self {
        case .notDetermined: "Pas encore demandé"
        case .fullAccess: "Accès complet accordé"
        case .writeOnly: "Écriture seule — insuffisant pour lire le calendrier"
        case .denied: "Refusé"
        case .restricted: "Restreint"
        case .unknown(let raw): "Inconnu (\(raw))"
        }
    }

    var canReadEvents: Bool {
        self == .fullAccess
    }
}
