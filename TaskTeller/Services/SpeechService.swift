//
//  SpeechService.swift
//  TAC342_FinalProject
//
//  Service for Apple Speech framework integration
//  Provides speech-to-text transcription for voice task capture
//

import Foundation
import Speech
import AVFoundation

enum SpeechError: LocalizedError {
    case notAuthorized
    case notAvailable
    case audioEngineError(String)
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Speech recognition is not authorized."
        case .notAvailable: return "Speech recognition is not available."
        case .audioEngineError(let message): return "Audio engine error: \(message)"
        case .recognitionFailed(let message): return "Recognition failed: \(message)"
        }
    }
}

class SpeechService: ObservableObject {
    static let shared = SpeechService()
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var isRecording: Bool = false
    @Published var transcribedText: String = ""
    @Published var errorMessage: String?
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        updateAuthorizationStatus()
    }
    
    func updateAuthorizationStatus() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    @MainActor
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    var isAvailable: Bool {
        guard let recognizer = speechRecognizer else { return false }
        return recognizer.isAvailable && authorizationStatus == .authorized
    }
    
    @MainActor
    func startTranscribing() throws {
        transcribedText = ""
        errorMessage = nil
        guard authorizationStatus == .authorized else { throw SpeechError.notAuthorized }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { throw SpeechError.notAvailable }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { throw SpeechError.audioEngineError("Failed to create audio engine") }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { throw SpeechError.audioEngineError("Failed to create request") }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let result = result { self.transcribedText = result.bestTranscription.formattedString }
                if let error = error { self.errorMessage = error.localizedDescription; self.stopTranscribing() }
                if result?.isFinal == true { self.stopTranscribing() }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }
    
    @MainActor
    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    @MainActor
    func reset() {
        stopTranscribing()
        transcribedText = ""
        errorMessage = nil
    }
}

