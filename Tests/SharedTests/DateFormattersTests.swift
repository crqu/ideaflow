import XCTest
@testable import IdeaFlow

final class DateFormattersTests: XCTestCase {

    func testFilenameSafeFormat() {
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        let result = DateFormatters.filenameSafe.string(from: date)
        XCTAssertEqual(result, "2024-03-15-143045")
    }

    func testFilenameStringExtension() {
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 25
        components.hour = 9
        components.minute = 5
        components.second = 3

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        XCTAssertEqual(date.filenameString, "2024-12-25-090503")
    }

    func testObsidianDateFormat() {
        var components = DateComponents()
        components.year = 2024
        components.month = 7
        components.day = 4

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        let result = DateFormatters.obsidianDate.string(from: date)
        XCTAssertEqual(result, "2024-07-04")
    }

    func testObsidianDateStringExtension() {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        XCTAssertEqual(date.obsidianDateString, "2024-01-01")
    }

    func testISO8601FormatContainsExpectedComponents() {
        let date = Date()
        let result = DateFormatters.iso8601.string(from: date)

        XCTAssertTrue(result.contains("T"), "ISO8601 should contain T separator")
        XCTAssertTrue(result.contains("."), "ISO8601 should contain fractional seconds")
    }

    func testISO8601StringExtension() {
        let date = Date()
        let result = date.iso8601String

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("T"))
    }

    func testDisplayDateFormatterNotEmpty() {
        let date = Date()
        let result = DateFormatters.displayDate.string(from: date)

        XCTAssertFalse(result.isEmpty)
    }

    func testDisplayStringExtension() {
        let date = Date()
        let result = date.displayString

        XCTAssertFalse(result.isEmpty)
    }

    func testFormattersAreReused() {
        let formatter1 = DateFormatters.filenameSafe
        let formatter2 = DateFormatters.filenameSafe

        XCTAssertTrue(formatter1 === formatter2, "DateFormatters should return the same instance")
    }
}
