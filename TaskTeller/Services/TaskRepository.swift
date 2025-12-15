//
//  TaskRepository.swift
//  TAC342_FinalProject
//
//  Repository for managing tasks in Firebase Firestore
//

import Foundation
import FirebaseFirestore

/// Repository class for task data operations with Firestore
class TaskRepository: ObservableObject {
    @Published var tasks: [TaskItem] = []
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var currentUserUID: String?
    
    private func tasksCollection(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("tasks")
    }
    
    func startObserving(for uid: String) {
        stopObserving()
        currentUserUID = uid
        
        listenerRegistration = tasksCollection(for: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    self.tasks = []
                    return
                }
                self.tasks = documents.compactMap { TaskItem(document: $0) }
            }
    }
    
    func stopObserving() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        currentUserUID = nil
        tasks = []
    }
    
    @MainActor
    func addTask(_ task: TaskItem) async throws {
        guard let uid = currentUserUID else { throw NSError(domain: "TaskRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]) }
        try await tasksCollection(for: uid).document(task.id).setData(task.asDictionary)
    }
    
    @MainActor
    func updateTask(_ task: TaskItem) async throws {
        guard let uid = currentUserUID else { throw NSError(domain: "TaskRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]) }
        try await tasksCollection(for: uid).document(task.id).setData(task.asDictionary, merge: true)
    }
    
    @MainActor
    func deleteTask(id taskId: String) async throws {
        guard let uid = currentUserUID else { throw NSError(domain: "TaskRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]) }
        try await tasksCollection(for: uid).document(taskId).delete()
    }
    
    @MainActor
    func toggleCompletion(for task: TaskItem) async throws {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        try await updateTask(updatedTask)
    }
    
    var todayTasks: [TaskItem] { tasks.filter { $0.isDueToday && !$0.isCompleted } }
    var overdueTasks: [TaskItem] { tasks.filter { $0.isOverdue } }
    var upcomingTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return calendar.startOfDay(for: dueDate) > today
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    var completedTasks: [TaskItem] { tasks.filter { $0.isCompleted } }
    var incompleteTasks: [TaskItem] { tasks.filter { !$0.isCompleted } }
}

