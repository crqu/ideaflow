# IdeaFlow

Capture voice ideas from Apple Watch → process with Claude AI → save to Obsidian vault.

## Prerequisites

- **Xcode 16+** with iOS 17 and watchOS 10 SDKs
- **XcodeGen** — install via Homebrew: `brew install xcodegen`
- **Claude API key** from [console.anthropic.com](https://console.anthropic.com)
- **Obsidian** with a local vault folder

## Quick Start

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Open in Xcode
open IdeaFlow.xcodeproj

# Build and run on simulator or device
```

## Architecture

```
┌─────────────────┐       ┌─────────────────┐
│  Apple Watch    │       │    iPhone       │
│                 │       │                 │
│  Voice capture  │──────▶│  Claude API     │
│  via dictation  │  WC   │  processing     │
│                 │       │                 │
└─────────────────┘       │  Obsidian       │
                          │  file write     │
                          └────────┬────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │  Obsidian Vault │
                          │  (Markdown)     │
                          └─────────────────┘
```

- **Watch app**: Captures voice via system dictation, sends transcript to iPhone via WatchConnectivity
- **iOS app**: Receives transcripts, calls Claude Haiku for processing, writes Markdown to Obsidian vault
- **Shared**: Data models used by both apps

## Setup

1. Generate project: `xcodegen generate`
2. Open `IdeaFlow.xcodeproj` in Xcode
3. Configure signing for both iOS and watchOS targets
4. Build and run on your devices
5. In the iOS app Settings tab:
   - Enter your Claude API key
   - Select your Obsidian vault folder

## Project Structure

```
├── project.yml              # XcodeGen project definition
├── IdeaFlow/                # iOS app
│   ├── IdeaFlowApp.swift
│   ├── Views/
│   └── Services/            # (Phase 3)
├── IdeaFlowWatch/           # watchOS app
│   ├── IdeaFlowWatchApp.swift
│   └── Views/
├── Shared/                  # Shared code
│   └── Models/
├── eval/                    # Factory eval harness
│   └── score.py
├── CLAUDE.md                # Coding guidelines
└── factory.md               # Factory configuration
```

## Development

This project uses the [Software Factory](https://github.com/anthropics/factory) system for iterative improvement.

```bash
# Run eval harness (static analysis)
python3 eval/score.py

# Lint (if swiftlint installed)
swiftlint lint
```

## License

MIT
