//
//  LoginView.swift
//  TAC342_FinalProject
//
//  Login screen for existing users
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field { case email, password }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile").font(.system(size: 70)).foregroundStyle(LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("TaskTeller").font(.custom("Avenir-Heavy", size: 36)).foregroundColor(.white)
                        Text("AI Smart Planner").font(.custom("Avenir-Medium", size: 16)).foregroundColor(Color(hex: "a0a0a0"))
                    }.padding(.top, 60)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            TextField("", text: $viewModel.email).textContentType(.emailAddress).keyboardType(.emailAddress).autocapitalization(.none).autocorrectionDisabled().focused($focusedField, equals: .email).padding().background(Color(hex: "2a2a4a")).cornerRadius(12).foregroundColor(.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .email ? Color(hex: "e94560") : Color.clear, lineWidth: 2))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            SecureField("", text: $viewModel.password).textContentType(.password).focused($focusedField, equals: .password).padding().background(Color(hex: "2a2a4a")).cornerRadius(12).foregroundColor(.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .password ? Color(hex: "e94560") : Color.clear, lineWidth: 2))
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error).font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "ff6b6b")).multilineTextAlignment(.center)
                        }
                        if let success = viewModel.successMessage {
                            Text(success).font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "4ade80")).multilineTextAlignment(.center)
                        }
                        
                        Button { focusedField = nil; Task { await viewModel.login() } } label: {
                            HStack {
                                if viewModel.isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                                else { Text("Sign In").font(.custom("Avenir-Heavy", size: 18)) }
                            }.frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")], startPoint: .leading, endPoint: .trailing)).cornerRadius(12).foregroundColor(.white)
                        }.disabled(viewModel.isLoading)
                        
                        Button { Task { await viewModel.sendPasswordReset() } } label: {
                            Text("Forgot Password?").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "e94560"))
                        }
                    }.padding(.horizontal, 32)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Don't have an account?").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                        NavigationLink { RegisterView() } label: {
                            Text("Create Account").font(.custom("Avenir-Heavy", size: 16)).foregroundColor(Color(hex: "e94560")).padding(.horizontal, 32).padding(.vertical, 12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "e94560"), lineWidth: 2))
                        }
                    }.padding(.bottom, 40)
                }
            }
        }.navigationBarHidden(true)
    }
}

