//
//  AuthRootView.swift
//  TAC342_FinalProject
//
//  Root view for the authentication flow
//

import SwiftUI

struct AuthRootView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}

