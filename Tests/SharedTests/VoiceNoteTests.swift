import XCTest
@testable import IdeaFlow

final class VoiceNoteTests: XCTestCase {

    func testVoiceNoteInitialization() {
        let note = VoiceNote(transcript: "Test transcript")

        XCTAssertFalse(note.id.uuidString.isEmpty)
        XCTAssertEqual(note.transcript, "Test transcript")
        XCTAssertEqual(note.status, .pending)
        XCTAssertNil(note.processedTitle)
        XCTAssertNil(note.processedContent)
        XCTAssertTrue(note.tags.isEmpty)
        XCTAssertTrue(note.actionItems.isEmpty)
    }

    func testVoiceNoteCustomInitialization() {
        let id = UUID()
        let timestamp = Date()
        let note = VoiceNote(
            id: id,
            transcript: "Custom note",
            timestamp: timestamp,
            processedTitle: "Title",
            processedContent: "Content",
            tags: ["tag1", "tag2"],
            actionItems: ["action1"],
            status: .completed
        )

        XCTAssertEqual(note.id, id)
        XCTAssertEqual(note.transcript, "Custom note")
        XCTAssertEqual(note.timestamp, timestamp)
        XCTAssertEqual(note.processedTitle, "Title")
        XCTAssertEqual(note.processedContent, "Content")
        XCTAssertEqual(note.tags, ["tag1", "tag2"])
        XCTAssertEqual(note.actionItems, ["action1"])
        XCTAssertEqual(note.status, .completed)
    }

    func testVoiceNoteEncodingDecoding() throws {
        let original = VoiceNote(
            transcript: "Encoded note",
            processedTitle: "Encoded Title",
            tags: ["swift", "testing"],
            actionItems: ["Write tests"],
            status: .processing
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VoiceNote.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.transcript, original.transcript)
        XCTAssertEqual(decoded.processedTitle, original.processedTitle)
        XCTAssertEqual(decoded.tags, original.tags)
        XCTAssertEqual(decoded.actionItems, original.actionItems)
        XCTAssertEqual(decoded.status, original.status)
    }

    func testProcessingStatusRawValues() {
        XCTAssertEqual(ProcessingStatus.pending.rawValue, "pending")
        XCTAssertEqual(ProcessingStatus.processing.rawValue, "processing")
        XCTAssertEqual(ProcessingStatus.completed.rawValue, "completed")
        XCTAssertEqual(ProcessingStatus.failed.rawValue, "failed")
    }

    func testProcessingStatusEncodingDecoding() throws {
        let statuses: [ProcessingStatus] = [.pending, .processing, .completed, .failed]

        for status in statuses {
            let encoder = JSONEncoder()
            let data = try encoder.encode(status)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ProcessingStatus.self, from: data)

            XCTAssertEqual(decoded, status)
        }
    }

    func testVoiceNoteStatusMutation() {
        var note = VoiceNote(transcript: "Mutable note")
        XCTAssertEqual(note.status, .pending)

        note.status = .processing
        XCTAssertEqual(note.status, .processing)

        note.status = .completed
        XCTAssertEqual(note.status, .completed)
    }

    func testVoiceNoteIdentifiable() {
        let note1 = VoiceNote(transcript: "Note 1")
        let note2 = VoiceNote(transcript: "Note 2")

        XCTAssertNotEqual(note1.id, note2.id)
    }
}
