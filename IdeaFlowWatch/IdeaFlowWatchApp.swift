import SwiftUI

@main
struct IdeaFlowWatchApp: App {
    @State private var sessionManager = WatchSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
        }
    }
}
