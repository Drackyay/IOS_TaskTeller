//
//  TaskListViewModel.swift
//  TAC342_FinalProject
//
//  View model for the Task List screen
//

import Foundation

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case upcoming = "Upcoming"
    case overdue = "Overdue"
    case completed = "Completed"
}

class TaskListViewModel: ObservableObject {
    private let taskRepository: TaskRepository
    private let userUID: String
    
    @Published var selectedFilter: TaskFilter = .all
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    init(taskRepository: TaskRepository, userUID: String) {
        self.taskRepository = taskRepository
        self.userUID = userUID
    }
    
    var filteredTasks: [TaskItem] {
        var tasks: [TaskItem]
        switch selectedFilter {
        case .all: tasks = taskRepository.tasks
        case .today: tasks = taskRepository.todayTasks
        case .upcoming: tasks = taskRepository.upcomingTasks
        case .overdue: tasks = taskRepository.overdueTasks
        case .completed: tasks = taskRepository.completedTasks
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            tasks = tasks.filter { $0.title.lowercased().contains(query) || ($0.notes?.lowercased().contains(query) ?? false) }
        }
        return tasks
    }
    
    var filterCounts: [TaskFilter: Int] {
        [.all: taskRepository.tasks.count, .today: taskRepository.todayTasks.count, .upcoming: taskRepository.upcomingTasks.count, .overdue: taskRepository.overdueTasks.count, .completed: taskRepository.completedTasks.count]
    }
    
    @MainActor
    func addTask(title: String, notes: String? = nil, dueDate: Date? = nil, priority: TaskPriority = .medium, category: TaskCategory = .other) async {
        isLoading = true
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority, category: category, ownerUID: userUID)
        do {
            try await taskRepository.addTask(task)
            successMessage = "Task added"
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
    
    @MainActor
    func deleteTask(_ task: TaskItem) async {
        do { try await taskRepository.deleteTask(id: task.id) }
        catch { errorMessage = error.localizedDescription }
    }
    
    @MainActor
    func toggleCompletion(_ task: TaskItem) async {
        do { try await taskRepository.toggleCompletion(for: task) }
        catch { errorMessage = error.localizedDescription }
    }
}

