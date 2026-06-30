import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: NotesViewModel

    var body: some View {
        TabView {
            NoteListView(viewModel: viewModel)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView(viewModel: NotesViewModel())
}
