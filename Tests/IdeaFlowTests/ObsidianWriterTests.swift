import XCTest
@testable import IdeaFlow

final class ObsidianWriterTests: XCTestCase {
    var tempDirectory: URL!
    var obsidianWriter: ObsidianWriter!

    override func setUp() async throws {
        try await super.setUp()

        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )

        obsidianWriter = ObsidianWriter()
        await obsidianWriter.setVaultURL(tempDirectory)
    }

    override func tearDown() async throws {
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }
        try await super.tearDown()
    }

    func testSaveNoteCreatesFile() async throws {
        let note = VoiceNote(
            transcript: "Test transcript for note",
            processedTitle: "Test Note",
            processedContent: "This is processed content.",
            tags: ["test", "example"],
            actionItems: ["Do something"],
            status: .completed
        )

        let fileURL = try await obsidianWriter.saveNote(note)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.lastPathComponent.hasSuffix(".md"))
        XCTAssertTrue(fileURL.lastPathComponent.contains("test-note"))
    }

    func testSaveNoteCreatesVoiceNotesSubfolder() async throws {
        let note = VoiceNote(
            transcript: "Test transcript",
            status: .completed
        )

        let fileURL = try await obsidianWriter.saveNote(note)

        let voiceNotesFolder = tempDirectory.appendingPathComponent("voice-notes")
        XCTAssertTrue(FileManager.default.fileExists(atPath: voiceNotesFolder.path))
        XCTAssertTrue(fileURL.path.contains("voice-notes"))
    }

    func testMarkdownFormatWithAllFields() async throws {
        let note = VoiceNote(
            transcript: "This is my voice note about buying groceries",
            processedTitle: "Grocery Shopping",
            processedContent: "Need to go shopping for weekly groceries.",
            tags: ["shopping", "todo"],
            actionItems: ["Buy milk", "Get bread"],
            status: .completed
        )

        let fileURL = try await obsidianWriter.saveNote(note)
        let content = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(content.contains("---"), "Should have YAML frontmatter")
        XCTAssertTrue(content.contains("created:"), "Should have created date")
        XCTAssertTrue(content.contains("tags:"), "Should have tags")
        XCTAssertTrue(content.contains("\"shopping\""), "Should have shopping tag")
        XCTAssertTrue(content.contains("\"todo\""), "Should have todo tag")
        XCTAssertTrue(content.contains("source: apple-watch"), "Should have source")
        XCTAssertTrue(content.contains("# Grocery Shopping"), "Should have H1 title")
        XCTAssertTrue(content.contains("Need to go shopping"), "Should have processed content")
        XCTAssertTrue(content.contains("## Action Items"), "Should have action items section")
        XCTAssertTrue(content.contains("- [ ] Buy milk"), "Should have checkbox items")
        XCTAssertTrue(content.contains("- [ ] Get bread"), "Should have checkbox items")
        XCTAssertTrue(content.contains("## Original Transcript"), "Should have transcript section")
        XCTAssertTrue(content.contains("> This is my voice note"), "Should have blockquote transcript")
    }

    func testMarkdownFormatWithoutOptionalFields() async throws {
        let note = VoiceNote(
            transcript: "Simple note without processing",
            status: .completed
        )

        let fileURL = try await obsidianWriter.saveNote(note)
        let content = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(content.contains("---"), "Should have YAML frontmatter")
        XCTAssertTrue(content.contains("source: apple-watch"))
        XCTAssertTrue(content.contains("# Voice Note"), "Should have fallback title")
        XCTAssertTrue(content.contains("## Original Transcript"))
        XCTAssertFalse(content.contains("## Action Items"), "Should not have action items section")
    }

    func testFilenameSanitization() async throws {
        let note = VoiceNote(
            transcript: "Test",
            processedTitle: "Hello! This is a test @#$% with special chars!!!",
            status: .completed
        )

        let fileURL = try await obsidianWriter.saveNote(note)
        let filename = fileURL.lastPathComponent

        XCTAssertFalse(filename.contains("!"))
        XCTAssertFalse(filename.contains("@"))
        XCTAssertFalse(filename.contains("#"))
        XCTAssertFalse(filename.contains("$"))
        XCTAssertFalse(filename.contains("%"))
        XCTAssertTrue(filename.hasSuffix(".md"))
    }

    func testFilenameLengthLimit() async throws {
        let longTitle = String(repeating: "word ", count: 50)
        let note = VoiceNote(
            transcript: "Test",
            processedTitle: longTitle,
            status: .completed
        )

        let fileURL = try await obsidianWriter.saveNote(note)
        let filename = fileURL.deletingPathExtension().lastPathComponent

        XCTAssertLessThanOrEqual(filename.count, 80)
    }

    func testNoVaultPathThrowsError() async {
        let writer = ObsidianWriter()
        await writer.clearVaultURL()

        let note = VoiceNote(transcript: "Test", status: .completed)

        do {
            _ = try await writer.saveNote(note)
            XCTFail("Should throw error when no vault path set")
        } catch ObsidianWriterError.noVaultPath {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testMultilineTranscriptInBlockquote() async throws {
        let note = VoiceNote(
            transcript: "Line one\nLine two\nLine three",
            status: .completed
        )

        let fileURL = try await obsidianWriter.saveNote(note)
        let content = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(content.contains("> Line one"))
        XCTAssertTrue(content.contains("> Line two"))
        XCTAssertTrue(content.contains("> Line three"))
    }
}
