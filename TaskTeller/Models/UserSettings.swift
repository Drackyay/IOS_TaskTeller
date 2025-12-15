//
//  UserSettings.swift
//  TAC342_FinalProject
//
//  Model for storing user preferences and settings
//

import Foundation

/// User settings and preferences stored in UserDefaults
class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    private enum Keys {
        static let autoAddToCalendar = "autoAddToCalendar"
        static let defaultCategory = "defaultCategory"
        static let defaultPriority = "defaultPriority"
        static let showCompletedTasks = "showCompletedTasks"
        static let enableVoiceFeedback = "enableVoiceFeedback"
    }
    
    @Published var autoAddToCalendar: Bool {
        didSet { UserDefaults.standard.set(autoAddToCalendar, forKey: Keys.autoAddToCalendar) }
    }
    
    @Published var defaultCategory: TaskCategory {
        didSet { UserDefaults.standard.set(defaultCategory.rawValue, forKey: Keys.defaultCategory) }
    }
    
    @Published var defaultPriority: TaskPriority {
        didSet { UserDefaults.standard.set(defaultPriority.rawValue, forKey: Keys.defaultPriority) }
    }
    
    @Published var showCompletedTasks: Bool {
        didSet { UserDefaults.standard.set(showCompletedTasks, forKey: Keys.showCompletedTasks) }
    }
    
    @Published var enableVoiceFeedback: Bool {
        didSet { UserDefaults.standard.set(enableVoiceFeedback, forKey: Keys.enableVoiceFeedback) }
    }
    
    private init() {
        self.autoAddToCalendar = UserDefaults.standard.bool(forKey: Keys.autoAddToCalendar)
        self.showCompletedTasks = UserDefaults.standard.object(forKey: Keys.showCompletedTasks) as? Bool ?? true
        self.enableVoiceFeedback = UserDefaults.standard.bool(forKey: Keys.enableVoiceFeedback)
        
        if let categoryRaw = UserDefaults.standard.string(forKey: Keys.defaultCategory),
           let category = TaskCategory(rawValue: categoryRaw) {
            self.defaultCategory = category
        } else {
            self.defaultCategory = .other
        }
        
        if let priorityRaw = UserDefaults.standard.string(forKey: Keys.defaultPriority),
           let priority = TaskPriority(rawValue: priorityRaw) {
            self.defaultPriority = priority
        } else {
            self.defaultPriority = .medium
        }
    }
    
    func resetToDefaults() {
        autoAddToCalendar = false
        defaultCategory = .other
        defaultPriority = .medium
        showCompletedTasks = true
        enableVoiceFeedback = false
    }
}

