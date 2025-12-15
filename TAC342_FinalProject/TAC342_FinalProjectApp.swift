//
//  TAC342_FinalProjectApp.swift
//  TAC342_FinalProject
//
//  TaskTeller - AI Smart Planner
//  Main app entry point that configures Firebase and manages authentication state
//

import SwiftUI
import FirebaseCore

/// App delegate to configure Firebase on launch
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase - must be called before any Firebase services are used
        FirebaseApp.configure()
        return true
    }
}

/// Main app structure for TaskTeller
@main
struct TAC342_FinalProjectApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Global session view model to manage authentication state
    @StateObject private var appSession = AppSessionViewModel()
    
    var body: some Scene {
        WindowGroup {
            // Show auth flow or main app based on login state
            if appSession.isLoading {
                // Show loading indicator while checking auth state
                LoadingView()
                    .environmentObject(appSession)
            } else if appSession.user != nil {
                // User is logged in - show main app
                MainTabView()
                    .environmentObject(appSession)
            } else {
                // User is not logged in - show auth flow
                AuthRootView()
                    .environmentObject(appSession)
            }
        }
    }
}

/// Simple loading view shown while checking authentication state
struct LoadingView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App icon placeholder
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "e94560"))
                
                Text("TaskTeller")
                    .font(.custom("Avenir-Heavy", size: 32))
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "e94560")))
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    /// Initialize a Color from a hex string (e.g., "FF5733" or "#FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
