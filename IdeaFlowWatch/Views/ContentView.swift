import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                CaptureView()
            }

            NavigationStack {
                StatusView()
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
        .environment(WatchSessionManager())
}
