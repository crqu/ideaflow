# IdeaFlow

Capture voice ideas from Apple Watch, process with Claude AI, and save to your Obsidian vault.

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            APPLE WATCH                                  │
│  ┌─────────────────┐                                                    │
│  │   CaptureView   │  User speaks idea via system dictation             │
│  │  "Tap to speak" │                                                    │
│  └────────┬────────┘                                                    │
│           │                                                             │
│           ▼                                                             │
│  ┌─────────────────────┐                                                │
│  │ WatchSessionManager │  Creates VoiceNote, queues transferUserInfo    │
│  │  (WatchConnectivity)│  Plays haptic feedback                         │
│  └────────┬────────────┘                                                │
└───────────┼─────────────────────────────────────────────────────────────┘
            │
            │ WatchConnectivity (transferUserInfo)
            │ Guaranteed background delivery
            ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                              iPHONE                                       │
│  ┌─────────────────────┐                                                  │
│  │ PhoneSessionManager │  Receives userInfo, reconstructs VoiceNote       │
│  │ (WCSessionDelegate) │  Passes to NotesViewModel                        │
│  └────────┬────────────┘                                                  │
│           │                                                               │
│           ▼                                                               │
│  ┌─────────────────┐       ┌─────────────────┐                            │
│  │  NotesViewModel │──────▶│  NoteProcessor  │                            │
│  │  (UI state)     │       │  (orchestrator) │                            │
│  └─────────────────┘       └────────┬────────┘                            │
│                                     │                                     │
│                     ┌───────────────┴───────────────┐                     │
│                     ▼                               ▼                     │
│           ┌─────────────────┐             ┌─────────────────┐             │
│           │  ClaudeClient   │             │ ObsidianWriter  │             │
│           │  (Haiku API)    │             │ (file write)    │             │
│           └────────┬────────┘             └────────┬────────┘             │
│                    │                               │                      │
└────────────────────┼───────────────────────────────┼──────────────────────┘
                     │                               │
                     ▼                               ▼
            ┌─────────────────┐             ┌─────────────────┐
            │  Anthropic API  │             │  Obsidian Vault │
            │  (Claude Haiku) │             │   voice-notes/  │
            └─────────────────┘             └─────────────────┘
```

## How It Works

1. **Watch app** - Tap the dictation field, speak your idea, tap "Save Idea"
2. **Watch → iPhone** - WatchConnectivity transfers the transcript via `transferUserInfo` (guaranteed delivery even if phone is asleep)
3. **Claude processing** - iPhone sends transcript to Claude Haiku API to generate title, polished content, tags, and action items
4. **Obsidian save** - Markdown file with YAML frontmatter is written directly to your vault's `voice-notes/` folder
5. **Sync** - Obsidian Sync, iCloud Drive, or your preferred sync method handles the rest

## Prerequisites

- **Xcode 16+** with iOS 17 and watchOS 10 SDKs
- **XcodeGen** - `brew install xcodegen`
- **Claude API key** from [console.anthropic.com](https://console.anthropic.com)
- **Obsidian vault** folder accessible on your iPhone

## Quick Start

```bash
# 1. Generate Xcode project
xcodegen generate

# 2. Open in Xcode
open IdeaFlow.xcodeproj

# 3. Configure signing for both targets:
#    - IdeaFlow (iOS)
#    - IdeaFlowWatch (watchOS)

# 4. Build and run on your devices (simulator doesn't support WatchConnectivity)
```

## Setup

After installing on your devices:

1. Open the **IdeaFlow** app on your iPhone
2. Go to the **Settings** tab
3. Enter your **Claude API key** (starts with `sk-ant-`)
4. Tap **Select Obsidian Vault** and choose your vault folder

Notes will be saved to `<vault>/voice-notes/YYYY-MM-DD-HHmmss-title.md`

## Project Structure

```
IdeaFlow/
├── project.yml                 # XcodeGen project definition
├── CLAUDE.md                   # Coding guidelines
├── factory.md                  # Factory eval configuration
├── eval/
│   └── score.py                # Static analysis eval harness
│
├── Shared/                     # Code shared between iOS and watchOS
│   ├── Models/
│   │   ├── VoiceNote.swift           # Voice note data model
│   │   └── ClaudeResponse.swift      # Claude API response types
│   └── Utilities/
│       ├── KeychainHelper.swift      # Secure API key storage
│       ├── DateFormatters.swift      # Date formatting helpers
│       ├── Logger.swift              # OSLog-based structured logging
│       └── PipelineMetrics.swift     # Pipeline timing observability
│
├── IdeaFlow/                   # iOS companion app
│   ├── IdeaFlowApp.swift             # App entry point, wires managers
│   ├── Views/
│   │   ├── ContentView.swift         # Main TabView
│   │   ├── NoteListView.swift        # Voice notes list with status badges
│   │   ├── NoteDetailView.swift      # Single note detail view
│   │   └── SettingsView.swift        # API key + vault configuration
│   ├── ViewModels/
│   │   └── NotesViewModel.swift      # Note state management
│   └── Services/
│       ├── ClaudeClient.swift        # Claude Haiku API client
│       ├── ObsidianWriter.swift      # Markdown file writer
│       ├── NoteProcessor.swift       # Pipeline orchestrator
│       └── PhoneSessionManager.swift # WatchConnectivity receiver
│
├── IdeaFlowWatch/              # watchOS app
│   ├── IdeaFlowWatchApp.swift        # Watch app entry point
│   ├── Views/
│   │   ├── ContentView.swift         # Main TabView
│   │   ├── CaptureView.swift         # Voice capture via dictation
│   │   └── StatusView.swift          # Pending notes + sync status
│   └── Services/
│       └── WatchSessionManager.swift # WatchConnectivity sender
│
└── Tests/                      # Unit tests
    ├── SharedTests/
    │   ├── VoiceNoteTests.swift
    │   ├── ClaudeResponseTests.swift
    │   └── DateFormattersTests.swift
    └── IdeaFlowTests/
        ├── ClaudeClientTests.swift
        └── ObsidianWriterTests.swift
```

## Using the Watch App

1. **Open IdeaFlow** on your Apple Watch
2. **Tap the text field** - system dictation UI appears
3. **Speak your idea** - the watch transcribes in real-time
4. **Tap "Save Idea"** - haptic confirms, note queues for transfer
5. **Check Status tab** - shows pending transfers and sync status

The iPhone processes notes in the background. Even if your phone is locked, notes will be processed when it wakes.

## Markdown Output

Each voice note becomes a Markdown file:

```markdown
---
created: 2024-01-15T10:30:00
tags: ["project", "feature-idea"]
source: apple-watch
---

# Build a voice note capture app

Create an app that captures voice notes from Apple Watch, processes them with AI, and saves to Obsidian.

## Action Items

- [ ] Research WatchConnectivity API
- [ ] Set up Claude API integration
- [ ] Design Obsidian export format

## Original Transcript

> build a voice note capture app that takes ideas from apple watch processes them with claude ai and saves them to my obsidian vault
```

## Error Handling

- **No API key** - Notes save with "[AI processing unavailable]" prefix
- **Claude API failure** - Graceful degradation to raw transcript with fallback title
- **No vault configured** - Notes remain in pending state until vault is set
- **Network issues** - Exponential backoff retry (up to 3 attempts)

## Development

```bash
# Run eval harness (static analysis)
python3 eval/score.py

# Lint (if swiftlint installed)
swiftlint lint
```

## Architecture Notes

- **Swift 6.1** with strict concurrency checking
- **Actors** for all services (thread-safe by design)
- **@Observable** for state management (iOS 17+)
- **No force unwrapping** - all optionals handled safely
- **Keychain** for API key storage (never in UserDefaults)
- **OSLog** for structured logging with pipeline metrics

## License

MIT
