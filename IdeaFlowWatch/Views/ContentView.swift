import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Tap to capture idea")
                    .font(.headline)
            }
            .navigationTitle("IdeaFlow")
        }
    }
}

#Preview {
    ContentView()
}
