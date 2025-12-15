//
//  AuthViewModel.swift
//  TAC342_FinalProject
//
//  View model for authentication views
//

import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let authService = FirebaseAuthService.shared
    
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    var isPasswordValid: Bool { password.count >= 6 }
    var passwordsMatch: Bool { password == confirmPassword }
    var canLogin: Bool { isEmailValid && isPasswordValid }
    var canRegister: Bool { isEmailValid && isPasswordValid && passwordsMatch }
    
    @MainActor
    func login() async {
        guard canLogin else {
            errorMessage = "Please enter a valid email and password (6+ characters)"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.login(email: email, password: password)
            clearForm()
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func register() async {
        guard canRegister else {
            errorMessage = passwordsMatch ? "Please enter a valid email and password" : "Passwords don't match"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.register(email: email, password: password)
            clearForm()
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func sendPasswordReset() async {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email address"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.sendPasswordReset(to: email)
            successMessage = "Password reset email sent to \(email)"
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        successMessage = nil
    }
}

