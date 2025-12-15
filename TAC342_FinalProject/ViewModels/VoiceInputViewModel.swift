//
//  VoiceInputViewModel.swift
//  TAC342_FinalProject
//
//  View model for the Voice Capture screen
//  Supports multiple tasks from single voice input
//

import Foundation
import Combine

enum SpeechAuthStatus {
    case notDetermined, authorized, denied, restricted
}

class VoiceInputViewModel: ObservableObject {
    private let taskRepository: TaskRepository
    private let userUID: String
    private let speechService = SpeechService.shared
    private let openAIService = OpenAIService.shared
    
    @Published var transcribedText: String = ""
    @Published var manualInput: String = ""
    @Published var isRecording: Bool = false
    @Published var parsedTasks: [ParsedTask] = []  // Changed to array
    @Published var isParsing: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var speechAuthStatus: SpeechAuthStatus = .notDetermined
    
    private var cancellables = Set<AnyCancellable>()
    
    init(taskRepository: TaskRepository, userUID: String) {
        self.taskRepository = taskRepository
        self.userUID = userUID
        speechService.$transcribedText.receive(on: DispatchQueue.main).assign(to: &$transcribedText)
        speechService.$isRecording.receive(on: DispatchQueue.main).assign(to: &$isRecording)
        speechService.$errorMessage.receive(on: DispatchQueue.main).sink { [weak self] error in
            if let error = error { self?.errorMessage = error }
        }.store(in: &cancellables)
        updateAuthStatus()
    }
    
    // For backwards compatibility
    var parsedTask: ParsedTask? {
        parsedTasks.first
    }
    
    func updateAuthStatus() {
        speechService.updateAuthorizationStatus()
        switch speechService.authorizationStatus {
        case .authorized: speechAuthStatus = .authorized
        case .denied: speechAuthStatus = .denied
        case .restricted: speechAuthStatus = .restricted
        default: speechAuthStatus = .notDetermined
        }
    }
    
    @MainActor
    func requestSpeechAuthorization() async {
        speechAuthStatus = await speechService.requestAuthorization() ? .authorized : .denied
    }
    
    @MainActor
    func startRecording() {
        errorMessage = nil
        parsedTasks = []
        do { try speechService.startTranscribing() }
        catch let error as SpeechError { errorMessage = error.errorDescription }
        catch { errorMessage = error.localizedDescription }
    }
    
    @MainActor
    func stopRecording() { speechService.stopTranscribing() }
    
    @MainActor
    func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }
    
    @MainActor
    func parseText() async {
        let textToParse = transcribedText.isEmpty ? manualInput : transcribedText
        guard !textToParse.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter or speak a task first"
            return
        }
        isParsing = true
        errorMessage = nil
        parsedTasks = []
        
        do {
            // Use the new multi-task parsing
            parsedTasks = try await openAIService.parseMultipleTasks(from: textToParse)
            if parsedTasks.isEmpty {
                errorMessage = "Could not parse any tasks from input"
            }
        } catch let error as OpenAIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isParsing = false
    }
    
    /// Save a single task at a specific index
    @MainActor
    func saveTask(at index: Int) async {
        guard index < parsedTasks.count else { return }
        isSaving = true
        let task = parsedTasks[index].toTaskItem(ownerUID: userUID)
        do {
            try await taskRepository.addTask(task)
            // Remove saved task from list
            parsedTasks.remove(at: index)
            if parsedTasks.isEmpty {
                successMessage = "All tasks saved!"
                reset()
            } else {
                successMessage = "Task saved! \(parsedTasks.count) remaining."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
    
    /// Save all parsed tasks at once
    @MainActor
    func saveAllTasks() async {
        guard !parsedTasks.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        
        var savedCount = 0
        for parsed in parsedTasks {
            let task = parsed.toTaskItem(ownerUID: userUID)
            do {
                try await taskRepository.addTask(task)
                savedCount += 1
            } catch {
                errorMessage = "Failed to save some tasks: \(error.localizedDescription)"
            }
        }
        
        if savedCount > 0 {
            successMessage = "\(savedCount) task\(savedCount > 1 ? "s" : "") saved successfully!"
            reset()
        }
        isSaving = false
    }
    
    /// Remove a parsed task without saving
    @MainActor
    func removeParsedTask(at index: Int) {
        guard index < parsedTasks.count else { return }
        parsedTasks.remove(at: index)
    }
    
    /// Update a parsed task's properties
    @MainActor
    func updateParsedTask(at index: Int, title: String? = nil, dueDate: Date? = nil, priority: TaskPriority? = nil, category: TaskCategory? = nil) {
        guard index < parsedTasks.count else { return }
        if let title = title { parsedTasks[index].title = title }
        if let dueDate = dueDate { parsedTasks[index].dueDate = dueDate }
        if let priority = priority { parsedTasks[index].priority = priority }
        if let category = category { parsedTasks[index].category = category }
    }
    
    @MainActor
    func quickSave() async {
        let text = (transcribedText.isEmpty ? manualInput : transcribedText).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { errorMessage = "Please enter a task"; return }
        isSaving = true
        let task = TaskItem(title: text, priority: UserSettings.shared.defaultPriority, category: UserSettings.shared.defaultCategory, ownerUID: userUID)
        do {
            try await taskRepository.addTask(task)
            successMessage = "Task added!"
            reset()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
    
    @MainActor
    func reset() {
        speechService.reset()
        transcribedText = ""
        manualInput = ""
        parsedTasks = []
        errorMessage = nil
    }
}
