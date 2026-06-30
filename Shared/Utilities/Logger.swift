import Foundation
import OSLog

enum IdeaFlowLogger {
    private static let subsystem = "com.ideaflow"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let sync = Logger(subsystem: subsystem, category: "sync")
    static let processing = Logger(subsystem: subsystem, category: "processing")
    static let storage = Logger(subsystem: subsystem, category: "storage")
}

extension Logger {
    func trace(_ message: String) {
        self.trace("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        self.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        self.info("\(message, privacy: .public)")
    }

    func notice(_ message: String) {
        self.notice("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        self.warning("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        self.error("\(message, privacy: .public)")
    }

    func fault(_ message: String) {
        self.fault("\(message, privacy: .public)")
    }

    func networkRequest(url: String, method: String) {
        self.debug("\(method) \(url, privacy: .public)")
    }

    func networkResponse(url: String, statusCode: Int, duration: TimeInterval) {
        let durationMs = Int(duration * 1000)
        self.info("\(url, privacy: .public) -> \(statusCode) (\(durationMs)ms)")
    }

    func networkError(url: String, error: Error) {
        self.error("\(url, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
    }
}
