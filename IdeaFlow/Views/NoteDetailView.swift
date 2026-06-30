import SwiftUI

struct NoteDetailView: View {
    let note: VoiceNote
    @Bindable var viewModel: NotesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                statusSection

                if let content = note.processedContent, !content.isEmpty {
                    contentSection(content)
                }

                if !note.tags.isEmpty {
                    tagsSection
                }

                if !note.actionItems.isEmpty {
                    actionItemsSection
                }

                transcriptSection
            }
            .padding()
        }
        .navigationTitle(note.processedTitle ?? "Voice Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: markdownContent) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    if note.status == .failed {
                        Button {
                            Task {
                                await viewModel.retryFailedNote(note)
                            }
                        } label: {
                            Label("Retry Processing", systemImage: "arrow.clockwise")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.processedTitle ?? "Voice Note")
                .font(.title2)
                .fontWeight(.bold)

            Text(note.timestamp.displayString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusSection: some View {
        HStack {
            statusBadge
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch note.status {
        case .pending:
            Label("Pending", systemImage: "clock")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .processing:
            Label("Processing", systemImage: "gearshape.2")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.2))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        case .completed:
            Label("Saved", systemImage: "checkmark.circle")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green.opacity(0.2))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        case .failed:
            Label("Failed", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        }
    }

    private var statusText: String {
        switch note.status {
        case .pending:
            return "Waiting to be processed"
        case .processing:
            return "Being processed by Claude AI"
        case .completed:
            return "Saved to Obsidian vault"
        case .failed:
            return "Processing failed, tap to retry"
        }
    }

    private func contentSection(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.headline)

            Text(content)
                .font(.body)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(note.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Action Items")
                .font(.headline)

            ForEach(note.actionItems, id: \.self) { item in
                HStack(alignment: .top) {
                    Image(systemName: "square")
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.body)
                }
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Original Transcript")
                .font(.headline)

            Text(note.transcript)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var markdownContent: String {
        var lines: [String] = []

        lines.append("# \(note.processedTitle ?? "Voice Note")")
        lines.append("")

        if let content = note.processedContent {
            lines.append(content)
            lines.append("")
        }

        if !note.tags.isEmpty {
            lines.append("Tags: \(note.tags.map { "#\($0)" }.joined(separator: " "))")
            lines.append("")
        }

        if !note.actionItems.isEmpty {
            lines.append("## Action Items")
            for item in note.actionItems {
                lines.append("- [ ] \(item)")
            }
            lines.append("")
        }

        lines.append("## Original Transcript")
        lines.append("> \(note.transcript)")

        return lines.joined(separator: "\n")
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(
            note: VoiceNote(
                transcript: "I need to remember to buy groceries and call mom tomorrow",
                processedTitle: "Reminder Tasks",
                processedContent: "Two important tasks to complete: shopping for groceries and calling mom.",
                tags: ["reminder", "personal", "todo"],
                actionItems: ["Buy groceries", "Call mom tomorrow"],
                status: .completed
            ),
            viewModel: NotesViewModel()
        )
    }
}
