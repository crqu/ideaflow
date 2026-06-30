import Foundation

enum ObsidianWriterError: Error, Sendable {
    case noVaultPath
    case invalidVaultPath
    case fileWriteFailed(Error)
    case directoryCreationFailed(Error)
}

actor ObsidianWriter {
    private static let vaultPathKey = "obsidianVaultPath"
    private static let subfolder = "voice-notes"

    var vaultURL: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: Self.vaultPathKey) else {
                return nil
            }
            return URL(fileURLWithPath: path)
        }
    }

    func setVaultURL(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: Self.vaultPathKey)
        IdeaFlowLogger.storage.info("Vault path set to: \(url.path)")
    }

    func clearVaultURL() {
        UserDefaults.standard.removeObject(forKey: Self.vaultPathKey)
        IdeaFlowLogger.storage.info("Vault path cleared")
    }

    func saveNote(_ note: VoiceNote) async throws -> URL {
        guard let vaultURL = vaultURL else {
            IdeaFlowLogger.storage.error("No vault path configured")
            throw ObsidianWriterError.noVaultPath
        }

        let voiceNotesFolder = vaultURL.appendingPathComponent(Self.subfolder)
        try await ensureDirectoryExists(voiceNotesFolder)

        let filename = generateFilename(for: note)
        let fileURL = voiceNotesFolder.appendingPathComponent(filename)

        let content = generateMarkdown(for: note)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            IdeaFlowLogger.storage.info("Saved note to: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            IdeaFlowLogger.storage.error("Failed to write note: \(error)")
            throw ObsidianWriterError.fileWriteFailed(error)
        }
    }

    private func ensureDirectoryExists(_ url: URL) async throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                IdeaFlowLogger.storage.info("Created directory: \(url.lastPathComponent)")
            } catch {
                IdeaFlowLogger.storage.error("Failed to create directory: \(error)")
                throw ObsidianWriterError.directoryCreationFailed(error)
            }
        }
    }

    private func generateFilename(for note: VoiceNote) -> String {
        let datePrefix = note.timestamp.filenameString
        let titleSlug = sanitizeForFilename(note.processedTitle ?? note.transcript)
        return "\(datePrefix)-\(titleSlug).md"
    }

    private func sanitizeForFilename(_ input: String) -> String {
        let maxLength = 50

        var slug = input
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(8)
            .joined(separator: "-")

        if slug.isEmpty {
            slug = "voice-note"
        }

        if slug.count > maxLength {
            slug = String(slug.prefix(maxLength))
        }

        return slug
    }

    private func generateMarkdown(for note: VoiceNote) -> String {
        var lines: [String] = []

        lines.append("---")
        lines.append("created: \(note.timestamp.obsidianDateString)")

        if !note.tags.isEmpty {
            let tagList = note.tags.map { "\"\($0)\"" }.joined(separator: ", ")
            lines.append("tags: [\(tagList)]")
        }

        lines.append("source: apple-watch")
        lines.append("---")
        lines.append("")

        let title = note.processedTitle ?? "Voice Note"
        lines.append("# \(title)")
        lines.append("")

        if let content = note.processedContent, !content.isEmpty {
            lines.append(content)
            lines.append("")
        }

        if !note.actionItems.isEmpty {
            lines.append("## Action Items")
            lines.append("")
            for item in note.actionItems {
                lines.append("- [ ] \(item)")
            }
            lines.append("")
        }

        lines.append("## Original Transcript")
        lines.append("")
        lines.append("> \(note.transcript.replacingOccurrences(of: "\n", with: "\n> "))")
        lines.append("")

        return lines.joined(separator: "\n")
    }
}
