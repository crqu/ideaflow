import Foundation

enum DateFormatters {
    /// ISO8601 formatter for API communication and data serialization
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Filename-safe formatter: YYYY-MM-DD-HHmmss
    static let filenameSafe: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Human-readable date for display
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Obsidian YAML frontmatter format: YYYY-MM-DD
    static let obsidianDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Date {
    /// Format date for use in filenames
    var filenameString: String {
        DateFormatters.filenameSafe.string(from: self)
    }

    /// Format date for ISO8601 serialization
    var iso8601String: String {
        DateFormatters.iso8601.string(from: self)
    }

    /// Format date for Obsidian frontmatter
    var obsidianDateString: String {
        DateFormatters.obsidianDate.string(from: self)
    }

    /// Format date for human display
    var displayString: String {
        DateFormatters.displayDate.string(from: self)
    }
}
