import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NotesTabView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct NotesTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No voice notes yet")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Voice Notes")
        }
    }
}

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Claude API") {
                    Text("API key not configured")
                        .foregroundStyle(.secondary)
                }

                Section("Obsidian Vault") {
                    Text("Vault folder not selected")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}
