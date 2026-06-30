import SwiftUI

@main
struct IdeaFlowApp: App {
    @State private var viewModel = NotesViewModel()
    @State private var phoneSessionManager = PhoneSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    setupWatchConnectivity()
                }
        }
    }

    private func setupWatchConnectivity() {
        phoneSessionManager.setNoteReceivedHandler { note in
            viewModel.addNote(transcript: note.transcript)
            Task {
                await viewModel.processPendingNotes()
            }
        }
    }
}
