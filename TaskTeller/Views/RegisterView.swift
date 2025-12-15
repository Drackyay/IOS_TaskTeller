//
//  RegisterView.swift
//  TAC342_FinalProject
//
//  Registration screen for new users
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field { case email, password, confirmPassword }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus").font(.system(size: 50)).foregroundStyle(LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("Create Account").font(.custom("Avenir-Heavy", size: 28)).foregroundColor(.white)
                        Text("Join TaskTeller today").font(.custom("Avenir-Medium", size: 16)).foregroundColor(Color(hex: "a0a0a0"))
                    }.padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            TextField("", text: $viewModel.email).textContentType(.emailAddress).keyboardType(.emailAddress).autocapitalization(.none).autocorrectionDisabled().focused($focusedField, equals: .email).padding().background(Color(hex: "2a2a4a")).cornerRadius(12).foregroundColor(.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .email ? Color(hex: "e94560") : Color.clear, lineWidth: 2))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            SecureField("", text: $viewModel.password).textContentType(.newPassword).focused($focusedField, equals: .password).padding().background(Color(hex: "2a2a4a")).cornerRadius(12).foregroundColor(.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .password ? Color(hex: "e94560") : Color.clear, lineWidth: 2))
                            Text("At least 6 characters").font(.custom("Avenir-Regular", size: 12)).foregroundColor(viewModel.isPasswordValid ? Color(hex: "4ade80") : Color(hex: "a0a0a0"))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            SecureField("", text: $viewModel.confirmPassword).textContentType(.newPassword).focused($focusedField, equals: .confirmPassword).padding().background(Color(hex: "2a2a4a")).cornerRadius(12).foregroundColor(.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .confirmPassword ? Color(hex: "e94560") : Color.clear, lineWidth: 2))
                            if !viewModel.confirmPassword.isEmpty {
                                Text(viewModel.passwordsMatch ? "Passwords match" : "Passwords don't match").font(.custom("Avenir-Regular", size: 12)).foregroundColor(viewModel.passwordsMatch ? Color(hex: "4ade80") : Color(hex: "ff6b6b"))
                            }
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error).font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "ff6b6b")).multilineTextAlignment(.center)
                        }
                        
                        Button { focusedField = nil; Task { await viewModel.register() } } label: {
                            HStack {
                                if viewModel.isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                                else { Text("Create Account").font(.custom("Avenir-Heavy", size: 18)) }
                            }.frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(colors: viewModel.canRegister ? [Color(hex: "e94560"), Color(hex: "ff6b6b")] : [Color(hex: "4a4a6a"), Color(hex: "4a4a6a")], startPoint: .leading, endPoint: .trailing)).cornerRadius(12).foregroundColor(.white)
                        }.disabled(viewModel.isLoading || !viewModel.canRegister)
                    }.padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        HStack { Image(systemName: "arrow.left"); Text("Back to Sign In") }.font(.custom("Avenir-Medium", size: 16)).foregroundColor(Color(hex: "a0a0a0"))
                    }.padding(.bottom, 40)
                }
            }
        }.navigationBarHidden(true)
    }
}

