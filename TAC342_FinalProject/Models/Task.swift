//
//  Task.swift
//  TAC342_FinalProject
//
//  Core data model representing a user task in TaskTeller
//  Stored in Firebase Firestore under users/{uid}/tasks
//

import Foundation
import FirebaseFirestore

/// Priority levels for tasks
enum TaskPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var colorName: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

/// Category types for organizing tasks
enum TaskCategory: String, Codable, CaseIterable {
    case work = "work"
    case personal = "personal"
    case school = "school"
    case health = "health"
    case shopping = "shopping"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .school: return "School"
        case .health: return "Health"
        case .shopping: return "Shopping"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .school: return "book.fill"
        case .health: return "heart.fill"
        case .shopping: return "cart.fill"
        case .other: return "tag.fill"
        }
    }
}

/// Main Task model for the TaskTeller app
struct TaskItem: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var notes: String?
    var dueDate: Date?
    var createdAt: Date
    var isCompleted: Bool
    var priority: TaskPriority
    var category: TaskCategory
    var calendarEventIdentifier: String?
    var ownerUID: String
    
    init(
        id: String = UUID().uuidString,
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
        category: TaskCategory = .other,
        calendarEventIdentifier: String? = nil,
        ownerUID: String
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.priority = priority
        self.category = category
        self.calendarEventIdentifier = calendarEventIdentifier
        self.ownerUID = ownerUID
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueThisWeek: Bool {
        guard let dueDate = dueDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
        return dueDate >= now && dueDate <= weekEnd
    }
}

// MARK: - Firestore Conversion
extension TaskItem {
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title,
            "createdAt": Timestamp(date: createdAt),
            "isCompleted": isCompleted,
            "priority": priority.rawValue,
            "category": category.rawValue,
            "ownerUID": ownerUID
        ]
        if let notes = notes { dict["notes"] = notes }
        if let dueDate = dueDate { dict["dueDate"] = Timestamp(date: dueDate) }
        if let calendarEventIdentifier = calendarEventIdentifier { dict["calendarEventIdentifier"] = calendarEventIdentifier }
        return dict
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let id = data["id"] as? String,
              let title = data["title"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let isCompleted = data["isCompleted"] as? Bool,
              let priorityRaw = data["priority"] as? String,
              let priority = TaskPriority(rawValue: priorityRaw),
              let categoryRaw = data["category"] as? String,
              let category = TaskCategory(rawValue: categoryRaw),
              let ownerUID = data["ownerUID"] as? String
        else { return nil }
        
        self.id = id
        self.title = title
        self.notes = data["notes"] as? String
        self.createdAt = createdAtTimestamp.dateValue()
        self.isCompleted = isCompleted
        self.priority = priority
        self.category = category
        self.ownerUID = ownerUID
        self.calendarEventIdentifier = data["calendarEventIdentifier"] as? String
        if let dueDateTimestamp = data["dueDate"] as? Timestamp {
            self.dueDate = dueDateTimestamp.dateValue()
        }
    }
}

