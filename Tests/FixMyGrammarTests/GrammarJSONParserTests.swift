import FixMyGrammarCore
import XCTest

final class GrammarJSONParserTests: XCTestCase {
    func testParsePlainJSON() throws {
        let raw = """
        {"correctedText":"Hello world.","issues":[]}
        """
        let parsed = try GrammarJSONParser.parse(from: raw)
        XCTAssertEqual(parsed.correctedText, "Hello world.")
        XCTAssertTrue(parsed.issues.isEmpty)
    }

    func testParseMarkdownCodeFence() throws {
        let raw = """
        ```json
        {"correctedText":"Hi.","issues":[{"title":"Test","detail":"Note","severity":"style"}]}
        ```
        """
        let parsed = try GrammarJSONParser.parse(from: raw)
        XCTAssertEqual(parsed.correctedText, "Hi.")
        XCTAssertEqual(parsed.issues.count, 1)
        XCTAssertEqual(parsed.issues[0].title, "Test")
        XCTAssertEqual(parsed.issues[0].detail, "Note")
        XCTAssertEqual(parsed.issues[0].severity, "style")
    }

    func testTrimsWhitespace() throws {
        let raw = """

          {"correctedText":"X","issues":[]}

        """
        let parsed = try GrammarJSONParser.parse(from: raw)
        XCTAssertEqual(parsed.correctedText, "X")
    }

    func testInvalidJSONThrows() {
        XCTAssertThrowsError(try GrammarJSONParser.parse(from: "not json"))
    }
}
