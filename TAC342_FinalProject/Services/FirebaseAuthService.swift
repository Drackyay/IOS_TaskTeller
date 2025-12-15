//
//  FirebaseAuthService.swift
//  TAC342_FinalProject
//
//  Service layer for Firebase Authentication
//

import Foundation
import FirebaseAuth

/// Errors that can occur during authentication
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Please enter a valid email address."
        case .weakPassword: return "Password must be at least 6 characters."
        case .emailAlreadyInUse: return "An account with this email already exists."
        case .userNotFound: return "No account found with this email."
        case .wrongPassword: return "Incorrect password. Please try again."
        case .networkError: return "Network error. Please check your connection."
        case .unknown(let message): return message
        }
    }
}

/// Service class for Firebase Authentication operations
class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()
    @Published var currentUser: User?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async { self?.currentUser = user }
        }
    }
    
    @MainActor
    func login(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    @MainActor
    func register(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return result.user
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    func logout() throws {
        try Auth.auth().signOut()
    }
    
    @MainActor
    func sendPasswordReset(to email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    private func mapFirebaseError(_ error: NSError) -> AuthError {
        guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
            return .unknown(error.localizedDescription)
        }
        switch errorCode {
        case .invalidEmail: return .invalidEmail
        case .weakPassword: return .weakPassword
        case .emailAlreadyInUse: return .emailAlreadyInUse
        case .userNotFound: return .userNotFound
        case .wrongPassword: return .wrongPassword
        case .networkError: return .networkError
        default: return .unknown(error.localizedDescription)
        }
    }
}

