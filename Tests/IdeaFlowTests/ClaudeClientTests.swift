import XCTest
@testable import IdeaFlow

final class ClaudeClientTests: XCTestCase {

    func testClaudeAPIRequestEncoding() throws {
        let request = ClaudeAPIRequest(
            model: "claude-haiku-4-5-20251001",
            maxTokens: 1024,
            messages: [ClaudeMessage(role: "user", content: "Test message")],
            system: "You are a helpful assistant"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["model"] as? String, "claude-haiku-4-5-20251001")
        XCTAssertEqual(json?["max_tokens"] as? Int, 1024)
        XCTAssertEqual(json?["system"] as? String, "You are a helpful assistant")

        let messages = json?["messages"] as? [[String: Any]]
        XCTAssertEqual(messages?.count, 1)
        XCTAssertEqual(messages?.first?["role"] as? String, "user")
        XCTAssertEqual(messages?.first?["content"] as? String, "Test message")
    }

    func testClaudeProcessedNoteDecoding() throws {
        let jsonString = """
        {
            "title": "Meeting Notes",
            "content": "Discussed project timeline and deliverables.",
            "tags": ["meeting", "work"],
            "action_items": ["Review docs", "Send email"]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let note = try decoder.decode(ClaudeProcessedNote.self, from: data)

        XCTAssertEqual(note.title, "Meeting Notes")
        XCTAssertEqual(note.content, "Discussed project timeline and deliverables.")
        XCTAssertEqual(note.tags, ["meeting", "work"])
        XCTAssertEqual(note.actionItems, ["Review docs", "Send email"])
    }

    func testClaudeProcessedNoteDecodingWithEmptyArrays() throws {
        let jsonString = """
        {
            "title": "Quick Thought",
            "content": "Just a random idea I had.",
            "tags": [],
            "action_items": []
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let note = try decoder.decode(ClaudeProcessedNote.self, from: data)

        XCTAssertEqual(note.title, "Quick Thought")
        XCTAssertEqual(note.content, "Just a random idea I had.")
        XCTAssertTrue(note.tags.isEmpty)
        XCTAssertTrue(note.actionItems.isEmpty)
    }

    func testClaudeAPIResponseDecoding() throws {
        let jsonString = """
        {
            "id": "msg_123",
            "type": "message",
            "role": "assistant",
            "content": [
                {
                    "type": "text",
                    "text": "{\\"title\\":\\"Test\\",\\"content\\":\\"Content\\",\\"tags\\":[],\\"action_items\\":[]}"
                }
            ],
            "model": "claude-haiku-4-5-20251001",
            "stop_reason": "end_turn",
            "stop_sequence": null,
            "usage": {
                "input_tokens": 100,
                "output_tokens": 50
            }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.id, "msg_123")
        XCTAssertEqual(response.type, "message")
        XCTAssertEqual(response.role, "assistant")
        XCTAssertEqual(response.model, "claude-haiku-4-5-20251001")
        XCTAssertEqual(response.stopReason, "end_turn")
        XCTAssertNil(response.stopSequence)
        XCTAssertEqual(response.usage.inputTokens, 100)
        XCTAssertEqual(response.usage.outputTokens, 50)

        XCTAssertEqual(response.content.count, 1)
        XCTAssertEqual(response.content.first?.type, "text")
        XCTAssertNotNil(response.content.first?.text)
    }

    func testMalformedJSONHandling() {
        let malformedJSON = "{ this is not valid json }"
        let data = malformedJSON.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeProcessedNote.self, from: data))
    }

    func testClaudeClientErrorTypes() {
        XCTAssertNotNil(ClaudeClientError.noApiKey)
        XCTAssertNotNil(ClaudeClientError.invalidURL)
        XCTAssertNotNil(ClaudeClientError.invalidResponse)
        XCTAssertNotNil(ClaudeClientError.rateLimited)
        XCTAssertNotNil(ClaudeClientError.serverError(500))
        XCTAssertNotNil(ClaudeClientError.httpError(statusCode: 400, message: "Bad request"))
        XCTAssertNotNil(ClaudeClientError.decodingError("Parse failed"))
    }
}
