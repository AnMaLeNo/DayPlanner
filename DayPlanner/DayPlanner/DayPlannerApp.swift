//
//  DayPlannerApp.swift
//  DayPlanner
//
//  App macOS DayPlanner.
//  Configure le container SwiftData avec les vrais modèles du domaine.
//

import SwiftUI
import SwiftData

@main
struct DayPlannerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Goal.self,
            PlanTask.self,
            Block.self,
            TaskType.self,
            Settings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
