import SwiftUI

@main
struct IdeaFlowApp: App {
    @State private var viewModel = NotesViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
