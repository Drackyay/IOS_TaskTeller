//
//  EventKitService.swift
//  TAC342_FinalProject
//
//  Service for interacting with Apple EventKit framework
//

import Foundation
import EventKit

enum EventKitError: LocalizedError {
    case accessDenied
    case accessRestricted
    case noDefaultCalendar
    case eventNotFound
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Calendar access was denied."
        case .accessRestricted: return "Calendar access is restricted."
        case .noDefaultCalendar: return "No default calendar found."
        case .eventNotFound: return "Calendar event not found."
        case .saveFailed(let message): return "Failed to save event: \(message)"
        }
    }
}

class EventKitService: ObservableObject {
    static let shared = EventKitService()
    let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var todayEvents: [EKEvent] = []
    
    private init() { updateAuthorizationStatus() }
    
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    @MainActor
    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                updateAuthorizationStatus()
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                updateAuthorizationStatus()
                return granted
            }
        } catch { return false }
    }
    
    var hasCalendarAccess: Bool {
        if #available(iOS 17.0, *) { return authorizationStatus == .fullAccess }
        else { return authorizationStatus == .authorized }
    }
    
    @MainActor
    func fetchTodayEvents() async {
        guard hasCalendarAccess else { return }
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        self.todayEvents = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
    
    func createEvent(from task: TaskItem) -> EKEvent? {
        guard hasCalendarAccess else { return nil }
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.notes = task.notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        if let dueDate = task.dueDate {
            event.startDate = dueDate
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: dueDate)
        } else {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.day! += 1
            components.hour = 9
            event.startDate = calendar.date(from: components) ?? Date()
            event.endDate = calendar.date(byAdding: .hour, value: 1, to: event.startDate)
        }
        event.addAlarm(EKAlarm(relativeOffset: -30 * 60))
        return event
    }
    
    @MainActor
    func saveEvent(_ event: EKEvent) async throws -> String {
        guard hasCalendarAccess else { throw EventKitError.accessDenied }
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch { throw EventKitError.saveFailed(error.localizedDescription) }
    }
    
    @MainActor
    func deleteEvent(identifier: String) async throws {
        guard hasCalendarAccess else { throw EventKitError.accessDenied }
        guard let event = eventStore.event(withIdentifier: identifier) else { throw EventKitError.eventNotFound }
        try eventStore.remove(event, span: .thisEvent)
    }
    
    func getEvent(identifier: String) -> EKEvent? {
        return eventStore.event(withIdentifier: identifier)
    }
}

