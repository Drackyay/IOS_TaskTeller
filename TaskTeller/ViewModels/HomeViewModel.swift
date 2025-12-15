//
//  HomeViewModel.swift
//  TAC342_FinalProject
//
//  View model for the Home screen
//

import Foundation
import EventKit
import Combine

class HomeViewModel: ObservableObject {
    private let taskRepository: TaskRepository
    private let eventKitService = EventKitService.shared
    private let openAIService = OpenAIService.shared
    
    @Published var todayEvents: [EKEvent] = []
    @Published var dailySummary: String?
    @Published var isLoadingSummary: Bool = false
    @Published var errorMessage: String?
    @Published var hasCalendarAccess: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(taskRepository: TaskRepository) {
        self.taskRepository = taskRepository
        eventKitService.$todayEvents.receive(on: DispatchQueue.main).assign(to: &$todayEvents)
    }
    
    var todayTasks: [TaskItem] { taskRepository.todayTasks }
    var overdueTasks: [TaskItem] { taskRepository.overdueTasks }
    var upcomingTasks: [TaskItem] { taskRepository.upcomingTasks }
    var todayTaskCount: Int { todayTasks.count }
    var todayEventCount: Int { todayEvents.count }
    
    @MainActor
    func requestCalendarAccess() async {
        let granted = await eventKitService.requestAccess()
        hasCalendarAccess = granted
        if granted { await fetchTodayEvents() }
    }
    
    @MainActor
    func fetchTodayEvents() async {
        await eventKitService.fetchTodayEvents()
    }
    
    @MainActor
    func generateDailySummary() async {
        isLoadingSummary = true
        do {
            dailySummary = try await openAIService.generateDailySummary(tasks: todayTasks, eventCount: todayEventCount)
        } catch {
            dailySummary = nil
        }
        isLoadingSummary = false
    }
    
    @MainActor
    func toggleTaskCompletion(_ task: TaskItem) async {
        do { try await taskRepository.toggleCompletion(for: task) }
        catch { errorMessage = error.localizedDescription }
    }
    
    @MainActor
    func loadData() async {
        eventKitService.updateAuthorizationStatus()
        hasCalendarAccess = eventKitService.hasCalendarAccess
        if hasCalendarAccess { await fetchTodayEvents() }
        try? await Task.sleep(nanoseconds: 500_000_000)
        await generateDailySummary()
    }
}

