import Foundation

actor NoteProcessor {
    private let claudeClient: ClaudeClient
    private let obsidianWriter: ObsidianWriter

    init(claudeClient: ClaudeClient = ClaudeClient(), obsidianWriter: ObsidianWriter = ObsidianWriter()) {
        self.claudeClient = claudeClient
        self.obsidianWriter = obsidianWriter
    }

    func process(_ note: VoiceNote) async -> VoiceNote {
        var updatedNote = note

        IdeaFlowLogger.processing.info("Starting pipeline for note: \(note.id)")
        updatedNote.status = .processing

        do {
            let processedData = try await processWithClaude(note.transcript)
            updatedNote.processedTitle = processedData.title
            updatedNote.processedContent = processedData.content
            updatedNote.tags = processedData.tags
            updatedNote.actionItems = processedData.actionItems
            IdeaFlowLogger.processing.info("Claude processing succeeded: \(processedData.title)")
        } catch {
            IdeaFlowLogger.processing.warning("Claude processing failed, saving raw transcript: \(error)")
            updatedNote.processedTitle = generateFallbackTitle(from: note.transcript)
            updatedNote.processedContent = note.transcript
            updatedNote.tags = []
            updatedNote.actionItems = []
        }

        do {
            let fileURL = try await obsidianWriter.saveNote(updatedNote)
            updatedNote.status = .completed
            IdeaFlowLogger.processing.info("Pipeline completed, saved to: \(fileURL.lastPathComponent)")
        } catch {
            IdeaFlowLogger.processing.error("Failed to save note: \(error)")
            updatedNote.status = .failed
        }

        return updatedNote
    }

    private func processWithClaude(_ transcript: String) async throws -> ClaudeProcessedNote {
        try await claudeClient.processVoiceNote(transcript)
    }

    private func generateFallbackTitle(from transcript: String) -> String {
        let words = transcript.split(separator: " ").prefix(5)
        if words.isEmpty {
            return "Voice Note"
        }
        return words.joined(separator: " ") + "..."
    }
}
