//
//  VoiceCaptureView.swift
//  TAC342_FinalProject
//
//  Voice capture view for speech-to-text task input
//  Supports multiple tasks from single voice input
//

import SwiftUI

struct VoiceCaptureView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @StateObject private var viewModel: VoiceInputViewModel
    @State private var isAnimating = false
    
    init(taskRepository: TaskRepository, userUID: String) {
        _viewModel = StateObject(wrappedValue: VoiceInputViewModel(taskRepository: taskRepository, userUID: userUID))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    if viewModel.speechAuthStatus == .notDetermined { authorizationPrompt }
                    else if viewModel.speechAuthStatus == .denied || viewModel.speechAuthStatus == .restricted { authorizationDenied }
                    else {
                        recordingSection
                        manualInputSection
                        
                        // Only show Parse button when there's text
                        if !viewModel.transcribedText.isEmpty || !viewModel.manualInput.isEmpty {
                            parseButton
                        }
                        
                        if !viewModel.transcribedText.isEmpty { transcriptionSection }
                        
                        // Show multiple parsed tasks
                        if !viewModel.parsedTasks.isEmpty {
                            parsedTasksSection
                        }
                        
                        if let error = viewModel.errorMessage { errorCard(error) }
                        if let success = viewModel.successMessage { successCard(success) }
                    }
                    Spacer(minLength: 100)
                }.padding()
            }
        }.navigationTitle("Voice Input").navigationBarTitleDisplayMode(.large).onAppear { viewModel.updateAuthStatus() }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill").font(.system(size: 50)).foregroundStyle(LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("Speak Your Tasks").font(.custom("Avenir-Heavy", size: 24)).foregroundColor(.white)
            Text("Describe one or multiple tasks naturally").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0")).multilineTextAlignment(.center)
        }.padding(.top, 20)
    }
    
    private var authorizationPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.badge.plus").font(.system(size: 40)).foregroundColor(Color(hex: "60a5fa"))
            Text("Enable Speech Recognition").font(.custom("Avenir-Heavy", size: 18)).foregroundColor(.white)
            Text("TaskTeller needs permission to transcribe your voice").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0")).multilineTextAlignment(.center)
            Button { Task { await viewModel.requestSpeechAuthorization() } } label: { Text("Enable").font(.custom("Avenir-Heavy", size: 16)).foregroundColor(.white).padding(.horizontal, 32).padding(.vertical, 12).background(Color(hex: "60a5fa")).cornerRadius(12) }
        }.padding().background(Color(hex: "1a1a2e")).cornerRadius(16)
    }
    
    private var authorizationDenied: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash").font(.system(size: 40)).foregroundColor(Color(hex: "ff6b6b"))
            Text("Speech Recognition Disabled").font(.custom("Avenir-Heavy", size: 18)).foregroundColor(.white)
            Text("Please enable speech recognition in Settings").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0")).multilineTextAlignment(.center)
            Button { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } } label: { Text("Open Settings").font(.custom("Avenir-Heavy", size: 16)).foregroundColor(.white).padding(.horizontal, 32).padding(.vertical, 12).background(Color(hex: "606060")).cornerRadius(12) }
        }.padding().background(Color(hex: "1a1a2e")).cornerRadius(16)
    }
    
    private var recordingSection: some View {
        VStack(spacing: 24) {
            Button { viewModel.toggleRecording(); isAnimating = viewModel.isRecording } label: {
                ZStack {
                    if viewModel.isRecording { Circle().stroke(Color(hex: "e94560").opacity(0.3), lineWidth: 4).frame(width: 120, height: 120).scaleEffect(isAnimating ? 1.3 : 1.0).opacity(isAnimating ? 0 : 1).animation(Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating) }
                    Circle().fill(viewModel.isRecording ? LinearGradient(colors: [Color(hex: "ff6b6b"), Color(hex: "e94560")], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color(hex: "2a2a4a"), Color(hex: "1a1a2e")], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 100, height: 100).shadow(color: viewModel.isRecording ? Color(hex: "e94560").opacity(0.5) : .clear, radius: 20)
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill").font(.system(size: 36)).foregroundColor(.white)
                }
            }.disabled(viewModel.isParsing || viewModel.isSaving)
            Text(viewModel.isRecording ? "Listening..." : "Tap to Start").font(.custom("Avenir-Medium", size: 16)).foregroundColor(viewModel.isRecording ? Color(hex: "e94560") : Color(hex: "a0a0a0"))
        }
    }
    
    private var manualInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Or type your tasks").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            HStack {
                TextField("e.g., Math exam tomorrow 4 PM and English exam Dec 11", text: $viewModel.manualInput).font(.custom("Avenir-Regular", size: 15)).foregroundColor(.white)
                if !viewModel.manualInput.isEmpty { Button { viewModel.manualInput = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Color(hex: "606060")) } }
            }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
        }
    }
    
    // Single Parse with AI button
    private var parseButton: some View {
        Button { Task { await viewModel.parseText() } } label: {
            HStack {
                if viewModel.isParsing {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Parsing...")
                } else {
                    Image(systemName: "sparkles")
                    Text("Parse with AI")
                }
            }
            .font(.custom("Avenir-Heavy", size: 16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
        }
        .disabled(viewModel.isParsing)
    }
    
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Transcription").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0")); Spacer(); Button { viewModel.reset() } label: { Text("Clear").font(.custom("Avenir-Medium", size: 12)).foregroundColor(Color(hex: "e94560")) } }
            Text(viewModel.transcribedText).font(.custom("Avenir-Regular", size: 16)).foregroundColor(.white).padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "1a1a2e")).cornerRadius(12)
        }
    }
    
    // MARK: - Multiple Parsed Tasks Section
    
    private var parsedTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles").foregroundColor(Color(hex: "e94560"))
                Text("Parsed Tasks (\(viewModel.parsedTasks.count))").font(.custom("Avenir-Heavy", size: 16)).foregroundColor(.white)
                Spacer()
                
                // Save All button
                if viewModel.parsedTasks.count > 1 {
                    Button { Task { await viewModel.saveAllTasks() } } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save All")
                        }
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "4ade80"))
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            
            // List of parsed tasks
            ForEach(Array(viewModel.parsedTasks.enumerated()), id: \.element.id) { index, task in
                parsedTaskCard(task: task, index: index)
            }
        }
    }
    
    private func parsedTaskCard(task: ParsedTask, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with task number and remove button
            HStack {
                Text("Task \(index + 1)").font(.custom("Avenir-Heavy", size: 14)).foregroundColor(Color(hex: "e94560"))
                Spacer()
                Button { viewModel.removeParsedTask(at: index) } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Color(hex: "606060"))
                }
            }
            
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Title").font(.custom("Avenir-Medium", size: 11)).foregroundColor(Color(hex: "808080"))
                Text(task.title).font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
            }
            
            // Due date and time
            if let dueDate = task.dueDate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due").font(.custom("Avenir-Medium", size: 11)).foregroundColor(Color(hex: "808080"))
                    HStack {
                        Text(dueDate, style: .date).font(.custom("Avenir-Medium", size: 14)).foregroundColor(.white)
                        Text(dueDate, style: .time).font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                    }
                }
            }
            
            // Priority and Category in row
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Circle().fill(priorityColor(task.priority)).frame(width: 8, height: 8)
                    Text(task.priority.displayName).font(.custom("Avenir-Medium", size: 13)).foregroundColor(.white)
                }
                HStack(spacing: 6) {
                    Image(systemName: task.category.iconName).font(.system(size: 11)).foregroundColor(Color(hex: "e94560"))
                    Text(task.category.displayName).font(.custom("Avenir-Medium", size: 13)).foregroundColor(.white)
                }
            }
            
            // Save individual task button
            Button { Task { await viewModel.saveTask(at: index) } } label: {
                HStack {
                    if viewModel.isSaving { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                    else { Image(systemName: "checkmark"); Text("Save This Task") }
                }.font(.custom("Avenir-Heavy", size: 14)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(hex: "4ade80")).cornerRadius(10)
            }.disabled(viewModel.isSaving)
        }
        .padding()
        .background(Color(hex: "1a1a2e"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "e94560").opacity(0.2), lineWidth: 1))
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority { case .low: return Color(hex: "4ade80"); case .medium: return Color(hex: "fbbf24"); case .high: return Color(hex: "ff6b6b") }
    }
    
    private func errorCard(_ message: String) -> some View {
        HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Color(hex: "ff6b6b")); Text(message).font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "ff6b6b")) }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "ff6b6b").opacity(0.1)).cornerRadius(12)
    }
    
    private func successCard(_ message: String) -> some View {
        HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "4ade80")); Text(message).font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "4ade80")) }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "4ade80").opacity(0.1)).cornerRadius(12)
    }
}
