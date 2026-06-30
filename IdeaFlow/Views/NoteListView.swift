import SwiftUI

struct NoteListView: View {
    @Bindable var viewModel: NotesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .navigationTitle("Voice Notes")
            .toolbar {
                if viewModel.isProcessing {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Voice Notes",
            systemImage: "waveform",
            description: Text("Voice notes from your Apple Watch will appear here")
        )
    }

    private var notesList: some View {
        List {
            ForEach(viewModel.sortedNotes) { note in
                NavigationLink(value: note) {
                    NoteRowView(note: note)
                }
            }
            .onDelete { offsets in
                viewModel.deleteNotes(at: offsets)
            }
        }
        .refreshable {
            await viewModel.processPendingNotes()
        }
        .navigationDestination(for: VoiceNote.self) { note in
            NoteDetailView(note: note, viewModel: viewModel)
        }
    }
}

struct NoteRowView: View {
    let note: VoiceNote

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)

                Text(note.timestamp.displayString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        if let processedTitle = note.processedTitle, !processedTitle.isEmpty {
            return processedTitle
        }
        let preview = String(note.transcript.prefix(50))
        return preview.isEmpty ? "Voice Note" : preview
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch note.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.orange)
        case .processing:
            ProgressView()
                .scaleEffect(0.8)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    NoteListView(viewModel: NotesViewModel())
}
