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
        let timer = PipelineTimer()

        IdeaFlowLogger.processing.info("Starting pipeline for note: \(note.id)")
        updatedNote.status = .processing
        timer.checkpoint("start")

        var claudeMs: Int?
        do {
            let processedData = try await processWithClaude(note.transcript)
            claudeMs = timer.elapsedSince("start")
            timer.checkpoint("claude_done")
            updatedNote.processedTitle = processedData.title
            updatedNote.processedContent = processedData.content
            updatedNote.tags = processedData.tags
            updatedNote.actionItems = processedData.actionItems
            IdeaFlowLogger.processing.info("Claude processing succeeded: \(processedData.title)")
        } catch {
            claudeMs = timer.elapsedSince("start")
            timer.checkpoint("claude_done")
            IdeaFlowLogger.processing.warning("Claude processing failed, saving raw transcript: \(error)")
            updatedNote.processedTitle = "[AI processing unavailable] " + generateFallbackTitle(from: note.transcript)
            updatedNote.processedContent = note.transcript
            updatedNote.tags = []
            updatedNote.actionItems = []
        }

        var fileWriteMs: Int?
        do {
            let fileURL = try await obsidianWriter.saveNote(updatedNote)
            fileWriteMs = timer.elapsedSince("claude_done")
            updatedNote.status = .completed
            IdeaFlowLogger.processing.info("Pipeline completed, saved to: \(fileURL.lastPathComponent)")
        } catch {
            fileWriteMs = timer.elapsedSince("claude_done")
            IdeaFlowLogger.processing.error("Failed to save note: \(error)")
            updatedNote.status = .failed
        }

        let metrics = PipelineMetrics(
            noteId: note.id,
            claudeApiMs: claudeMs,
            fileWriteMs: fileWriteMs,
            totalMs: timer.elapsed()
        )
        metrics.log()

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
