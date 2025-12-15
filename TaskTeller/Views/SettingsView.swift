//
//  SettingsView.swift
//  TAC342_FinalProject
//
//  Settings screen for user preferences and account management
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @ObservedObject private var settings = UserSettings.shared
    @State private var showSignOutConfirmation = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    profileSection
                    taskDefaultsSection
                    displayPreferencesSection
                    aboutSection
                    signOutSection
                    Spacer(minLength: 100)
                }.padding()
            }
        }.navigationTitle("Settings").navigationBarTitleDisplayMode(.large)
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) { appSession.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure you want to sign out?") }
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) { settings.resetToDefaults() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will reset all settings to their default values.") }
    }
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 80, height: 80)
                Text(String(appSession.displayName.prefix(1)).uppercased()).font(.custom("Avenir-Heavy", size: 32)).foregroundColor(.white)
            }
            Text(appSession.displayName).font(.custom("Avenir-Heavy", size: 20)).foregroundColor(.white)
            Text(appSession.userEmail).font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
        }.frame(maxWidth: .infinity).padding(.vertical, 24).background(Color(hex: "1a1a2e")).cornerRadius(16)
    }
    
    private var taskDefaultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TASK DEFAULTS").font(.custom("Avenir-Heavy", size: 12)).foregroundColor(Color(hex: "606060")).padding(.leading, 4)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "flag.fill").foregroundColor(Color(hex: "fbbf24")).frame(width: 24)
                    Text("Default Priority").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                    Spacer()
                    Picker("Priority", selection: $settings.defaultPriority) { ForEach(TaskPriority.allCases, id: \.self) { Text($0.displayName).tag($0) } }.pickerStyle(.menu).tint(Color(hex: "e94560"))
                }.padding()
                Divider().background(Color(hex: "2a2a4a"))
                HStack {
                    Image(systemName: "tag.fill").foregroundColor(Color(hex: "60a5fa")).frame(width: 24)
                    Text("Default Category").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                    Spacer()
                    Picker("Category", selection: $settings.defaultCategory) { ForEach(TaskCategory.allCases, id: \.self) { Text($0.displayName).tag($0) } }.pickerStyle(.menu).tint(Color(hex: "e94560"))
                }.padding()
            }.background(Color(hex: "1a1a2e")).cornerRadius(12)
        }
    }
    
    private var displayPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DISPLAY").font(.custom("Avenir-Heavy", size: 12)).foregroundColor(Color(hex: "606060")).padding(.leading, 4)
            VStack(spacing: 0) {
                Toggle(isOn: $settings.showCompletedTasks) {
                    HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "4ade80")).frame(width: 24); Text("Show Completed Tasks").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white) }
                }.tint(Color(hex: "e94560")).padding()
                Divider().background(Color(hex: "2a2a4a"))
                Toggle(isOn: $settings.autoAddToCalendar) {
                    HStack { Image(systemName: "calendar.badge.plus").foregroundColor(Color(hex: "a78bfa")).frame(width: 24); Text("Auto Add to Calendar").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white) }
                }.tint(Color(hex: "e94560")).padding()
            }.background(Color(hex: "1a1a2e")).cornerRadius(12)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ABOUT").font(.custom("Avenir-Heavy", size: 12)).foregroundColor(Color(hex: "606060")).padding(.leading, 4)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "info.circle.fill").foregroundColor(Color(hex: "60a5fa")).frame(width: 24)
                    Text("Version").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                    Spacer()
                    Text("1.0.0 (1)").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                }.padding()
                Divider().background(Color(hex: "2a2a4a"))
                Button { showResetConfirmation = true } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise").foregroundColor(Color(hex: "fbbf24")).frame(width: 24)
                        Text("Reset Settings").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                        Spacer()
                    }.padding()
                }
            }.background(Color(hex: "1a1a2e")).cornerRadius(12)
        }
    }
    
    private var signOutSection: some View {
        Button { showSignOutConfirmation = true } label: {
            HStack { Image(systemName: "rectangle.portrait.and.arrow.right"); Text("Sign Out") }.font(.custom("Avenir-Heavy", size: 16)).foregroundColor(Color(hex: "ff6b6b")).frame(maxWidth: .infinity).padding().background(Color(hex: "ff6b6b").opacity(0.1)).cornerRadius(12)
        }.padding(.top, 16)
    }
}

