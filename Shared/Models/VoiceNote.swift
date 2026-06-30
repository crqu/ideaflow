import Foundation

struct VoiceNote: Codable, Identifiable, Sendable {
    let id: UUID
    let transcript: String
    let timestamp: Date
    var processedTitle: String?
    var processedContent: String?
    var tags: [String]
    var actionItems: [String]
    var status: ProcessingStatus

    init(
        id: UUID = UUID(),
        transcript: String,
        timestamp: Date = Date(),
        processedTitle: String? = nil,
        processedContent: String? = nil,
        tags: [String] = [],
        actionItems: [String] = [],
        status: ProcessingStatus = .pending
    ) {
        self.id = id
        self.transcript = transcript
        self.timestamp = timestamp
        self.processedTitle = processedTitle
        self.processedContent = processedContent
        self.tags = tags
        self.actionItems = actionItems
        self.status = status
    }
}

enum ProcessingStatus: String, Codable, Sendable {
    case pending
    case processing
    case completed
    case failed
}
