import Foundation

struct PipelineMetrics: Sendable {
    let noteId: UUID
    let watchToPhoneMs: Int?
    let claudeApiMs: Int?
    let fileWriteMs: Int?
    let totalMs: Int?

    init(
        noteId: UUID,
        watchToPhoneMs: Int? = nil,
        claudeApiMs: Int? = nil,
        fileWriteMs: Int? = nil,
        totalMs: Int? = nil
    ) {
        self.noteId = noteId
        self.watchToPhoneMs = watchToPhoneMs
        self.claudeApiMs = claudeApiMs
        self.fileWriteMs = fileWriteMs
        self.totalMs = totalMs
    }

    func log() {
        var parts: [String] = ["Pipeline metrics for \(noteId.uuidString.prefix(8)):"]

        if let watch = watchToPhoneMs {
            parts.append("watch→phone=\(watch)ms")
        }
        if let claude = claudeApiMs {
            parts.append("claude=\(claude)ms")
        }
        if let file = fileWriteMs {
            parts.append("file=\(file)ms")
        }
        if let total = totalMs {
            parts.append("total=\(total)ms")
        }

        IdeaFlowLogger.processing.info("\(parts.joined(separator: " "))")
    }
}

final class PipelineTimer: @unchecked Sendable {
    private let startTime: Date
    private var checkpoints: [(name: String, time: Date)] = []
    private let lock = NSLock()

    init() {
        self.startTime = Date()
    }

    func checkpoint(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        checkpoints.append((name, Date()))
    }

    func elapsed() -> Int {
        Int(Date().timeIntervalSince(startTime) * 1000)
    }

    func elapsedSince(_ checkpointName: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        guard let checkpoint = checkpoints.first(where: { $0.name == checkpointName }) else {
            return nil
        }
        return Int(Date().timeIntervalSince(checkpoint.time) * 1000)
    }

    func durationBetween(_ from: String, _ to: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        guard let fromCheckpoint = checkpoints.first(where: { $0.name == from }),
              let toCheckpoint = checkpoints.first(where: { $0.name == to }) else {
            return nil
        }
        return Int(toCheckpoint.time.timeIntervalSince(fromCheckpoint.time) * 1000)
    }
}
