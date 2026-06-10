//
//  FreeSlotCalculator.swift
//  DayPlanner
//
//  Calcul pur des créneaux libres : retire les événements occupés
//  des fenêtres de travail configurées.
//

import Foundation

enum FreeSlotCalculator {
    static func freeSlots(
        events: [CalendarEvent],
        in range: DateInterval,
        rules: SchedulingRules,
        calendar: Calendar = .current
    ) -> [FreeSlot] {
        guard range.start < range.end, rules.workStartMinutes < rules.workEndMinutes else {
            return []
        }

        var slots: [FreeSlot] = []
        var dayStart = calendar.startOfDay(for: range.start)

        while dayStart < range.end {
            defer {
                dayStart = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? range.end
            }

            let weekday = calendar.component(.weekday, from: dayStart)
            guard rules.workDays.contains(weekday) else { continue }

            guard
                let workStart = calendar.date(byAdding: .minute, value: rules.workStartMinutes, to: dayStart),
                let workEnd = calendar.date(byAdding: .minute, value: rules.workEndMinutes, to: dayStart)
            else { continue }

            let rawWorkInterval = DateInterval(start: workStart, end: workEnd)
            guard let workInterval = rawWorkInterval.intersection(with: range) else { continue }

            let busyIntervals = mergedBusyIntervals(
                from: events,
                clippedTo: workInterval
            )

            slots.append(contentsOf: subtract(busyIntervals, from: workInterval)
                .filter { $0.duration >= rules.minBlockDuration }
                .map { FreeSlot(start: $0.start, end: $0.end) })
        }

        return slots
    }

    private static func mergedBusyIntervals(
        from events: [CalendarEvent],
        clippedTo container: DateInterval
    ) -> [DateInterval] {
        let intervals = events.compactMap { event -> DateInterval? in
            guard event.start < event.end else { return nil }
            return DateInterval(start: event.start, end: event.end).intersection(with: container)
        }
        .sorted { $0.start < $1.start }

        var merged: [DateInterval] = []

        for interval in intervals {
            guard let last = merged.last else {
                merged.append(interval)
                continue
            }

            if interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(
                    start: last.start,
                    end: max(last.end, interval.end)
                )
            } else {
                merged.append(interval)
            }
        }

        return merged
    }

    private static func subtract(
        _ busyIntervals: [DateInterval],
        from container: DateInterval
    ) -> [DateInterval] {
        var free: [DateInterval] = []
        var cursor = container.start

        for busy in busyIntervals {
            if cursor < busy.start {
                free.append(DateInterval(start: cursor, end: busy.start))
            }
            cursor = max(cursor, busy.end)
        }

        if cursor < container.end {
            free.append(DateInterval(start: cursor, end: container.end))
        }

        return free
    }
}
