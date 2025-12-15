//
//  AppSessionViewModel.swift
//  TAC342_FinalProject
//
//  Global session view model that manages authentication state
//

import Foundation
import FirebaseAuth

class AppSessionViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    let taskRepository = TaskRepository()
    private let authService = FirebaseAuthService.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() { setupAuthStateListener() }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.user = user
                self.isLoading = false
                if let user = user {
                    self.taskRepository.startObserving(for: user.uid)
                } else {
                    self.taskRepository.stopObserving()
                }
            }
        }
    }
    
    @MainActor
    func signOut() {
        do {
            try authService.logout()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var userEmail: String { user?.email ?? "Unknown" }
    var displayName: String { user?.displayName ?? user?.email?.components(separatedBy: "@").first ?? "User" }
    var userUID: String? { user?.uid }
    var isSignedIn: Bool { user != nil }
}

