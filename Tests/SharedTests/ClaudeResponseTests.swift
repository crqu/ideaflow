import XCTest
@testable import IdeaFlow

final class ClaudeResponseTests: XCTestCase {

    func testClaudeProcessedNoteDecoding() throws {
        let json = """
        {
            "title": "Meeting Notes",
            "content": "Discussed project timeline",
            "tags": ["meeting", "planning"],
            "action_items": ["Schedule follow-up", "Review docs"]
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ClaudeProcessedNote.self, from: data)

        XCTAssertEqual(decoded.title, "Meeting Notes")
        XCTAssertEqual(decoded.content, "Discussed project timeline")
        XCTAssertEqual(decoded.tags, ["meeting", "planning"])
        XCTAssertEqual(decoded.actionItems, ["Schedule follow-up", "Review docs"])
    }

    func testClaudeProcessedNoteEncoding() throws {
        let note = ClaudeProcessedNote(
            title: "Test Note",
            content: "Test content",
            tags: ["test"],
            actionItems: ["Do something"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(note)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"action_items\""))
        XCTAssertTrue(json.contains("\"Test Note\""))
    }

    func testClaudeAPIResponseDecoding() throws {
        let json = """
        {
            "id": "msg_123",
            "type": "message",
            "role": "assistant",
            "content": [
                {
                    "type": "text",
                    "text": "Hello, world!"
                }
            ],
            "model": "claude-haiku-4-5-20251001",
            "stop_reason": "end_turn",
            "stop_sequence": null,
            "usage": {
                "input_tokens": 10,
                "output_tokens": 5
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.id, "msg_123")
        XCTAssertEqual(response.type, "message")
        XCTAssertEqual(response.role, "assistant")
        XCTAssertEqual(response.model, "claude-haiku-4-5-20251001")
        XCTAssertEqual(response.stopReason, "end_turn")
        XCTAssertNil(response.stopSequence)
        XCTAssertEqual(response.content.count, 1)
        XCTAssertEqual(response.content[0].type, "text")
        XCTAssertEqual(response.content[0].text, "Hello, world!")
        XCTAssertEqual(response.usage.inputTokens, 10)
        XCTAssertEqual(response.usage.outputTokens, 5)
    }

    func testClaudeAPIRequestEncoding() throws {
        let request = ClaudeAPIRequest(
            model: "claude-haiku-4-5-20251001",
            maxTokens: 1024,
            messages: [
                ClaudeMessage(role: "user", content: "Hello")
            ],
            system: "You are a helpful assistant"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"max_tokens\":1024"))
        XCTAssertTrue(json.contains("\"model\":\"claude-haiku-4-5-20251001\""))
        XCTAssertTrue(json.contains("\"system\":\"You are a helpful assistant\""))
    }

    func testClaudeMessageEncoding() throws {
        let message = ClaudeMessage(role: "user", content: "Test message")

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let decoded = try JSONDecoder().decode(ClaudeMessage.self, from: data)

        XCTAssertEqual(decoded.role, "user")
        XCTAssertEqual(decoded.content, "Test message")
    }

    func testClaudeUsageDecoding() throws {
        let json = """
        {
            "input_tokens": 100,
            "output_tokens": 250
        }
        """

        let data = json.data(using: .utf8)!
        let usage = try JSONDecoder().decode(ClaudeUsage.self, from: data)

        XCTAssertEqual(usage.inputTokens, 100)
        XCTAssertEqual(usage.outputTokens, 250)
    }
}
