//
//  MainTabView.swift
//  TAC342_FinalProject
//
//  Main tab navigation for authenticated users
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @State private var selectedTab: Tab = .home
    
    enum Tab: String { case home = "Home", tasks = "Tasks", voice = "Voice" }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(taskRepository: appSession.taskRepository)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)
            
            NavigationStack {
                TaskListView(taskRepository: appSession.taskRepository, userUID: appSession.userUID ?? "")
            }
            .tabItem { Label("Tasks", systemImage: "checklist") }
            .tag(Tab.tasks)
            
            NavigationStack {
                VoiceCaptureView(taskRepository: appSession.taskRepository, userUID: appSession.userUID ?? "")
            }
            .tabItem { Label("Voice", systemImage: "mic.fill") }
            .tag(Tab.voice)
        }
        .tint(Color(hex: "e94560"))
    }
}

