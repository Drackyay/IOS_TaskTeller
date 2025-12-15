# TaskTeller - AI Smart Planner

An AI-powered daily planner iOS app that converts natural language into structured, trackable tasks.

## Setup Instructions

### 1. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Add an iOS app with bundle identifier: `com.yourname.TAC342-FinalProject`
4. Download `GoogleService-Info.plist` and add it to the `TAC342_FinalProject/TAC342_FinalProject/` folder
5. In Firebase Console, enable:
   - **Authentication** > Sign-in method > Email/Password
   - **Firestore Database** > Create database (start in test mode for development)

### 2. Add Firebase SDK via Swift Package Manager

1. In Xcode, go to File > Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select these packages:
   - FirebaseAuth
   - FirebaseFirestore

### 3. OpenAI API Key

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Open `TAC342_FinalProject/Secrets.plist`
3. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual API key

### 4. Privacy Permissions

The app requires these permissions (already configured in Info.plist):
- **Calendar Access**: For EventKit integration
- **Microphone Access**: For Speech recognition
- **Speech Recognition**: For voice-to-text features

## Features

- **AI Task Input**: Type or speak natural language to create tasks
- **Smart Daily View**: Today, Upcoming, and Overdue task sections
- **Calendar Integration**: Add tasks to your calendar with one tap
- **Voice Capture**: Dictate tasks using speech recognition
- **Cloud Sync**: Tasks sync across devices via Firebase

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI with UIKit integration
- **Backend**: Firebase Auth + Firestore
- **APIs**: OpenAI for NLP, EventKit for Calendar, Speech for voice

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
TAC342_FinalProject/
├── Models/           # Data models (Task, ParsedTask, UserSettings)
├── ViewModels/       # MVVM view models
├── Views/            # SwiftUI views
├── Services/         # Firebase, OpenAI, EventKit, Speech services
├── UIKitBridging/    # UIViewControllerRepresentable wrappers
└── Config/           # Configuration helpers
```

