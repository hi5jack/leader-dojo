# Leader Dojo - Native iOS/macOS App

A privacy-first leadership practice operating system for managing projects, commitments, and reflections.

## Overview

Leader Dojo is a native iOS and macOS application built with SwiftUI and SwiftData. It helps leaders track their projects, manage commitments (I Owe / Waiting For), and reflect on their leadership journey.

### Key Features

- **Projects**: Track multiple projects with status, priority, and owner notes
- **Entries**: Record meetings, notes, decisions, and updates on a timeline
- **Commitments**: Manage I Owe and Waiting For commitments with due dates and priorities
- **Dashboard**: Weekly focus view and projects needing attention
- **Quick Capture**: Fast mobile-first note capture
- **Reflections**: Weekly/monthly structured reflection with AI-generated questions
- **AI Summaries**: Generate meeting summaries and commitment suggestions (requires OpenAI API key)

## Technical Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Cloud Sync | CloudKit (iCloud) |
| AI Service | OpenAI API |
| Minimum iOS | 17.0 |
| Minimum macOS | 14.0 |

## Privacy First

- **All data stored locally** on your device
- **iCloud sync** keeps your devices in sync privately
- **No third-party servers** - your data never leaves Apple's ecosystem
- **API keys stored in Keychain** - securely encrypted

## Project Structure

```
LeaderDojo/
├── App/
│   ├── LeaderDojoApp.swift      # App entry point
│   └── ContentView.swift        # Main navigation
├── Models/
│   ├── Project.swift            # Project model
│   ├── Entry.swift              # Timeline entry model
│   ├── Commitment.swift         # Commitment model
│   └── Reflection.swift         # Reflection model
├── Views/
│   ├── Dashboard/               # Dashboard views
│   ├── Projects/                # Project list & detail
│   ├── Entries/                 # Entry creation & detail
│   ├── Commitments/             # Commitment management
│   ├── Reflections/             # Reflection views
│   ├── Capture/                 # Quick capture
│   └── Settings/                # App settings
├── Services/
│   ├── AIService.swift          # OpenAI integration
│   └── DataImportService.swift  # Import from web app
└── Utilities/
    ├── KeychainManager.swift    # Secure storage
    └── Extensions.swift         # Helper extensions
```

## Setup Instructions

### Prerequisites

- Xcode 15.0+
- Apple Developer account (for CloudKit)
- iOS 17.0+ device or simulator
- macOS 14.0+ (for Mac app)

### Steps

1. **Open in Xcode**
   ```bash
   cd app/LeaderDojo
   open LeaderDojo.xcodeproj
   ```

2. **Configure Signing**
   - Select your development team
   - Update bundle identifier if needed

3. **Enable CloudKit**
   - Go to Signing & Capabilities
   - Add "iCloud" capability
   - Enable CloudKit
   - Create a CloudKit container

4. **Build and Run**
   - Select your target device
   - Press Cmd+R to build and run

### AI Features Setup

1. Get an OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys)
2. Open the app and go to Settings
3. Enter your API key (stored securely in Keychain)

## Data Import

You can import data from the web version of Leader Dojo:

1. Export your data as JSON from the web app
2. Open Leader Dojo → Settings → Import from Web App
3. Paste the JSON content
4. Tap Import

## Architecture

### SwiftData Models

All models use `@Model` macro for SwiftData integration:
- Automatic persistence
- CloudKit sync via `cloudKitDatabase` configuration
- Relationships managed automatically

### Navigation

- **iPhone**: Tab bar navigation
- **iPad/Mac**: Sidebar navigation with `NavigationSplitView`
- One codebase adapts to all form factors

### AI Integration

The `AIService` actor provides:
- Meeting summarization
- Commitment suggestion extraction
- Prep briefing generation
- Reflection question generation

All AI calls require user-provided OpenAI API key.

## Future Enhancements

- [ ] Apple Intelligence integration (local LLM)
- [ ] Widgets for iOS and macOS
- [ ] Siri shortcuts
- [ ] Watch app for quick capture
- [ ] Export functionality
- [ ] Backend proxy for shared API key

## License

Private - All rights reserved


