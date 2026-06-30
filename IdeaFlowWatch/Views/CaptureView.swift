import SwiftUI
import WatchKit

struct CaptureView: View {
    @Environment(WatchSessionManager.self) private var sessionManager
    @State private var transcript = ""
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TextField("Tap to speak...", text: $transcript, axis: .vertical)
                    .lineLimit(3...6)

                Button(action: saveIdea) {
                    Label("Save Idea", systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if showConfirmation {
                    Text("Sent!")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Capture")
    }

    private func saveIdea() {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        sessionManager.sendVoiceNote(trimmedTranscript)
        transcript = ""

        withAnimation {
            showConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showConfirmation = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        CaptureView()
            .environment(WatchSessionManager())
    }
}
