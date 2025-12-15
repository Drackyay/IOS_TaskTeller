//
//  TaskDetailViewModel.swift
//  TAC342_FinalProject
//
//  View model for the Task Detail/Edit screen
//

import Foundation
import EventKit

class TaskDetailViewModel: ObservableObject {
    @Published var task: TaskItem
    private let taskRepository: TaskRepository
    private let eventKitService = EventKitService.shared
    
    @Published var isEditing: Bool = false
    @Published var isSaving: Bool = false
    @Published var showEventEditor: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasCalendarAccess: Bool = false
    
    private var originalTask: TaskItem
    
    init(task: TaskItem, taskRepository: TaskRepository) {
        self.task = task
        self.originalTask = task
        self.taskRepository = taskRepository
        eventKitService.updateAuthorizationStatus()
        hasCalendarAccess = eventKitService.hasCalendarAccess
    }
    
    var hasChanges: Bool { task != originalTask }
    var hasCalendarEvent: Bool { task.calendarEventIdentifier != nil }
    var linkedCalendarEvent: EKEvent? {
        guard let identifier = task.calendarEventIdentifier else { return nil }
        return eventKitService.getEvent(identifier: identifier)
    }
    
    @MainActor
    func saveChanges() async {
        guard hasChanges else { return }
        isSaving = true
        do {
            try await taskRepository.updateTask(task)
            originalTask = task
            isEditing = false
            successMessage = "Task saved"
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
    
    func revertChanges() {
        task = originalTask
        isEditing = false
    }
    
    @MainActor
    func toggleCompletion() async {
        task.isCompleted.toggle()
        do {
            try await taskRepository.updateTask(task)
            originalTask = task
        } catch {
            task.isCompleted.toggle()
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func deleteTask() async throws {
        try await taskRepository.deleteTask(id: task.id)
    }
    
    @MainActor
    func requestCalendarAccess() async {
        hasCalendarAccess = await eventKitService.requestAccess()
    }
    
    func createCalendarEvent() -> EKEvent? {
        return eventKitService.createEvent(from: task)
    }
    
    var eventStore: EKEventStore { eventKitService.eventStore }
    
    @MainActor
    func handleEventSaved(eventIdentifier: String) async {
        task.calendarEventIdentifier = eventIdentifier
        do {
            try await taskRepository.updateTask(task)
            originalTask = task
            successMessage = "Event added to calendar"
        } catch { errorMessage = error.localizedDescription }
    }
    
    @MainActor
    func unlinkCalendarEvent() async {
        guard let identifier = task.calendarEventIdentifier else { return }
        try? await eventKitService.deleteEvent(identifier: identifier)
        task.calendarEventIdentifier = nil
        do {
            try await taskRepository.updateTask(task)
            originalTask = task
            successMessage = "Calendar event removed"
        } catch { errorMessage = error.localizedDescription }
    }
}

