//
//  ParsedTask.swift
//  TAC342_FinalProject
//
//  Model representing the AI-parsed result from natural language input
//  Supports multiple tasks from a single voice input
//

import Foundation

/// Represents a task parsed from natural language by OpenAI
struct ParsedTask: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var dueDate: Date?
    var priority: TaskPriority
    var category: TaskCategory
    var notes: String?
    
    init(id: String = UUID().uuidString, title: String, dueDate: Date? = nil, priority: TaskPriority = .medium, category: TaskCategory = .other, notes: String? = nil) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.category = category
        self.notes = notes
    }
    
    func toTaskItem(ownerUID: String) -> TaskItem {
        TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority, category: category, ownerUID: ownerUID)
    }
}

extension ParsedTask {
    /// Raw response structure from OpenAI API for a single task
    struct OpenAITaskResponse: Codable {
        let title: String
        let dueDate: String?
        let dueTime: String?  // NEW: Time field like "4 PM", "6 PM"
        let priority: String?
        let category: String?
        let notes: String?
    }
    
    /// Response structure for multiple tasks
    struct OpenAIMultiTaskResponse: Codable {
        let tasks: [OpenAITaskResponse]
    }
    
    init(from response: OpenAITaskResponse) {
        self.id = UUID().uuidString
        self.title = response.title
        self.notes = response.notes
        self.priority = TaskPriority(rawValue: response.priority?.lowercased() ?? "") ?? .medium
        self.category = TaskCategory(rawValue: response.category?.lowercased() ?? "") ?? .other
        
        // Parse date and time together
        if let dueDateStr = response.dueDate {
            var date = ParsedTask.parseDate(from: dueDateStr)
            
            // If we have a time, combine it with the date
            if let date = date, let dueTimeStr = response.dueTime,
               let time = ParsedTask.parseTime(from: dueTimeStr) {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = time.hour
                components.minute = time.minute
                self.dueDate = calendar.date(from: components)
            } else {
                self.dueDate = date
            }
        }
    }
    
    static func parseDate(from string: String) -> Date? {
        let lowercased = string.lowercased().trimmingCharacters(in: .whitespaces)
        let calendar = Calendar.current
        let now = Date()
        
        switch lowercased {
        case "today": return calendar.startOfDay(for: now)
        case "tomorrow": return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        case "next week": return calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: now))
        default: break
        }
        
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        if let targetWeekday = weekdays.firstIndex(where: { lowercased.contains($0) }) {
            let currentWeekday = calendar.component(.weekday, from: now)
            var daysToAdd = targetWeekday - (currentWeekday - 1)
            if daysToAdd <= 0 { daysToAdd += 7 }
            return calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now))
        }
        
        // Try parsing specific dates like "December 11", "December 14"
        let dateFormats = [
            "MMMM d, yyyy",
            "MMMM d yyyy", 
            "MMMM d",
            "MMM d, yyyy",
            "MMM d yyyy",
            "MMM d",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "d MMMM yyyy",
            "d MMMM"
        ]
        
        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US")
            
            // For formats without year, default to current/next year
            if let date = formatter.date(from: string) {
                if !format.contains("yyyy") {
                    // Add current year
                    var components = calendar.dateComponents([.month, .day], from: date)
                    components.year = calendar.component(.year, from: now)
                    if let dateWithYear = calendar.date(from: components) {
                        // If the date has passed, use next year
                        if dateWithYear < now {
                            components.year = calendar.component(.year, from: now) + 1
                            return calendar.date(from: components)
                        }
                        return dateWithYear
                    }
                }
                return date
            }
        }
        
        // Try ISO 8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        if let date = isoFormatter.date(from: string) { return date }
        
        return nil
    }
    
    /// Parse time string like "4 PM", "6 PM" and combine with a date
    static func parseTime(from string: String) -> (hour: Int, minute: Int)? {
        let lowercased = string.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Match patterns like "4 PM", "4PM", "16:00"
        let patterns = [
            "([0-9]{1,2})\\s*(am|pm)",
            "([0-9]{1,2}):([0-9]{2})\\s*(am|pm)?",
            "([0-9]{1,2})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
                
                if let hourRange = Range(match.range(at: 1), in: lowercased),
                   var hour = Int(lowercased[hourRange]) {
                    
                    var minute = 0
                    if match.numberOfRanges > 2, let minuteRange = Range(match.range(at: 2), in: lowercased),
                       let min = Int(lowercased[minuteRange]) {
                        minute = min
                    }
                    
                    // Check for PM
                    if lowercased.contains("pm") && hour < 12 {
                        hour += 12
                    } else if lowercased.contains("am") && hour == 12 {
                        hour = 0
                    }
                    
                    return (hour, minute)
                }
            }
        }
        return nil
    }
}
