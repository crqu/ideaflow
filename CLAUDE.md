# IdeaFlow

Voice note capture from Apple Watch → Claude AI processing → Obsidian vault.

## Language & Frameworks

- **Swift 6.1** with strict concurrency checking
- **SwiftUI** for all UI (iOS 17.0+, watchOS 10.0+)
- **WatchConnectivity** for Watch↔Phone communication

## Architecture

```
IdeaFlow/           # iOS companion app
├── IdeaFlowApp.swift
├── Views/
└── Services/       # ClaudeClient, ObsidianWriter, NoteProcessor

IdeaFlowWatch/      # watchOS app
├── IdeaFlowWatchApp.swift
├── Views/
└── Services/       # WatchConnectivityManager

Shared/             # Code shared between iOS and watchOS
└── Models/         # VoiceNote, ClaudeResponse
```

## Key Patterns

- **Actors** for all services (ClaudeClient, ObsidianWriter) — thread-safe by design
- **@Observable** for state management (not @ObservableObject)
- **Codable** for all data models crossing process boundaries
- **async/await** for all asynchronous operations

## Conventions

- One type per file, filename matches type name
- Views in `Views/` directory
- Services (actors) in `Services/` directory
- Models in `Shared/Models/`
- Use SF Symbols for icons
- No force unwrapping (`!`) — use guard/if-let or nil coalescing
- No hardcoded API keys — use Keychain

## Project Generation

This project uses XcodeGen. Run `xcodegen generate` to create the .xcodeproj from project.yml.

## Commands

```bash
# Generate Xcode project
xcodegen generate

# Build (requires Xcode)
xcodebuild -scheme IdeaFlow -destination 'platform=iOS Simulator,name=iPhone 16'

# Lint (if swiftlint installed)
swiftlint lint
```
