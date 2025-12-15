# TaskTeller

An AI-powered iOS daily planner that converts natural language into structured, trackable tasks.

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-yellow)

## Features

- **🎙️ Voice Input** - Speak naturally to create tasks using Apple's Speech Recognition
- **🤖 AI Task Parsing** - OpenAI GPT converts natural language into structured tasks with dates, times, and priorities
- **📅 Calendar Integration** - Seamlessly add tasks to Apple Calendar via EventKit
- **☁️ Cloud Sync** - Tasks sync across devices with Firebase Firestore
- **🔐 Secure Authentication** - Email/password login with Firebase Auth
- **📊 Smart Dashboard** - View today's tasks, upcoming items, and overdue reminders

## Architecture

### Design Pattern: MVVM (Model-View-ViewModel)

```
┌─────────────────────────────────────────────────────────────┐
│                         Views (SwiftUI)                      │
│  LoginView │ HomeView │ TaskListView │ VoiceCaptureView     │
└─────────────────────────┬───────────────────────────────────┘
                          │ @StateObject / @EnvironmentObject
┌─────────────────────────▼───────────────────────────────────┐
│                       ViewModels                             │
│  AuthViewModel │ HomeViewModel │ TaskListViewModel          │
│  VoiceInputViewModel │ TaskDetailViewModel                   │
└─────────────────────────┬───────────────────────────────────┘
                          │ Dependency Injection
┌─────────────────────────▼───────────────────────────────────┐
│                        Services                              │
│  FirebaseAuthService │ TaskRepository │ OpenAIService       │
│  EventKitService │ SpeechService                             │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                         Models                               │
│  TaskItem │ ParsedTask │ UserSettings                        │
└─────────────────────────────────────────────────────────────┘
```

### UIKit Integration

Uses `UIViewControllerRepresentable` to bridge `EKEventEditViewController` into SwiftUI for native calendar event editing.

## Tech Stack

| Category | Technology |
|----------|------------|
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM with Combine |
| **Authentication** | Firebase Auth |
| **Database** | Firebase Firestore (real-time sync) |
| **AI/NLP** | OpenAI GPT-3.5-turbo |
| **Voice Recognition** | Apple Speech Framework |
| **Calendar** | Apple EventKit |
| **Audio** | AVFoundation |

## API & SDK Integrations

### OpenAI API
- Natural language parsing for task extraction
- Extracts: title, due date/time, priority, category
- Daily task summary generation

### Firebase
- **Auth**: Email/password authentication with session persistence
- **Firestore**: Real-time task synchronization with offline support

### Apple Frameworks
- **EventKit**: Calendar read/write access, event creation and management
- **Speech**: On-device speech-to-text transcription
- **AVFoundation**: Microphone audio capture

## Project Structure

```
TaskTeller/
├── TaskTellerApp.swift          # App entry point
├── Config/
│   └── OpenAIConfig.swift       # API key management
├── Models/
│   ├── Task.swift               # Core task model
│   ├── ParsedTask.swift         # AI-parsed task structure
│   └── UserSettings.swift       # Local preferences
├── ViewModels/
│   ├── AppSessionViewModel.swift    # Auth state management
│   ├── AuthViewModel.swift          # Login/register logic
│   ├── HomeViewModel.swift          # Dashboard data
│   ├── TaskListViewModel.swift      # Task CRUD operations
│   ├── TaskDetailViewModel.swift    # Single task editing
│   └── VoiceInputViewModel.swift    # Speech + AI coordination
├── Views/
│   ├── AuthRootView.swift       # Auth navigation
│   ├── LoginView.swift          # Login UI
│   ├── RegisterView.swift       # Registration UI
│   ├── MainTabView.swift        # Tab navigation
│   ├── HomeView.swift           # Dashboard
│   ├── TaskListView.swift       # Task list
│   ├── TaskDetailView.swift     # Task editor
│   ├── VoiceCaptureView.swift   # Voice input
│   └── SettingsView.swift       # User settings
├── Services/
│   ├── FirebaseAuthService.swift    # Auth operations
│   ├── TaskRepository.swift         # Firestore CRUD
│   ├── OpenAIService.swift          # GPT integration
│   ├── EventKitService.swift        # Calendar operations
│   └── SpeechService.swift          # Voice transcription
└── UIKitBridging/
    └── EventEditViewControllerRepresentable.swift
```

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Firebase project
- OpenAI API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Drackyay/IOS_TaskTeller.git
   cd IOS_TaskTeller
   ```

2. **Configure Firebase**
   - Create a project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download `GoogleService-Info.plist` and add to `TaskTeller/` folder

3. **Configure OpenAI**
   - Get an API key from [OpenAI Platform](https://platform.openai.com/)
   - Create `TaskTeller/Secrets.plist`:
     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
     <dict>
         <key>OPENAI_API_KEY</key>
         <string>your-api-key-here</string>
     </dict>
     </plist>
     ```

4. **Open in Xcode**
   ```bash
   open TaskTeller.xcodeproj
   ```

5. **Build and run**

## Screenshots

*Coming soon*

## License

MIT License

## Author

Built with ❤️ using SwiftUI and AI
