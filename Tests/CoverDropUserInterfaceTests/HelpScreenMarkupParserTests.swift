import Combine
@testable import CoverDropUserInterface
import SwiftUI
import XCTest

final class HelpScreenContentTests: XCTestCase {
    func testParseHighlightedStringIntoAttributedString() {
        let input = "We strive to ~highlight~ only the important parts. Especially, in ~long examples~."

        let parser = HighlightedTextParser(highlightColor: .yellow)
        let attributedString = parser.parseIntoAttributedString(input)

        let runs = attributedString.runs
        XCTAssertEqual(runs.count, 5)

        let texts = runs.makeIterator().map { run in String(attributedString[run.range].characters) }
        let colors = runs.makeIterator().map { run in run.foregroundColor }

        XCTAssertEqual(texts[0], "We strive to ")
        XCTAssertEqual(colors[0], nil)

        XCTAssertEqual(texts[1], "highlight")
        XCTAssertEqual(colors[1], .yellow)

        XCTAssertEqual(texts[2], " only the important parts. Especially, in ")
        XCTAssertEqual(colors[2], nil)

        XCTAssertEqual(texts[3], "long examples")
        XCTAssertEqual(colors[3], .yellow)

        XCTAssertEqual(texts[4], ".")
        XCTAssertEqual(colors[4], nil)
    }

    func testParseHelpScreenMarkup_allComponentsValid() throws {
        let input = """
        # Here goes the main headline

        BLOCKQUOTE
        Followed by an inspirational quote.
        Someone
        with authority

        DIVIDER

        ## This medium headline gives structure

        ### Small header

        Followed by a long text that will wrap into multiple lines, so we can test those typographic features.

        EXAMPLE
        We strive to ~highlight~ only the important parts. Especially, in ~long examples~.

        ### Example of a special component

        We have the following cool component to illustrate the passphrase example.

        PASSPHRASE_BOXES apple waterfall diamond

        ### Another small header

        Some more text followed by a list and a divider.

        - Lists are fun
        - Who would not agree? Especially with items that go over multiple lines.

        DIVIDER

        BUTTON
        Click here
        Button description
        button_id_somewhere
        """

        let parser = HelpScreenMarkupParser(highlightColor: .yellow)
        let components = try parser.parseHelpScreenMarkup(markup: input)

        XCTAssertEqual(components.count, 15)

        if case let .headline(text, level) = components[0] {
            XCTAssertEqual(text, "Here goes the main headline")
            XCTAssertEqual(level, .headline1)
        } else {
            XCTFail("Expected .headline")
        }

        if case let .blockQuote(text, authorName, authorTagLine) = components[1] {
            XCTAssertEqual(text, "Followed by an inspirational quote.")
            XCTAssertEqual(authorName, "Someone")
            XCTAssertEqual(authorTagLine, "with authority")
        } else {
            XCTFail("Expected .blockQuote")
        }

        if case .divider = components[2] {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .divider")
        }

        if case let .headline(text, level) = components[3] {
            XCTAssertEqual(text, "This medium headline gives structure")
            XCTAssertEqual(level, .headline2)
        } else {
            XCTFail("Expected .headline")
        }

        if case let .headline(text, level) = components[4] {
            XCTAssertEqual(text, "Small header")
            XCTAssertEqual(level, .headline3)
        } else {
            XCTFail("Expected .headline")
        }

        if case let .text(content) = components[5] {
            XCTAssertEqual(
                content,
                "Followed by a long text that will wrap into multiple lines, so we can test those typographic features."
            )
        } else {
            XCTFail("Expected .text")
        }

        if case let .example(annotatedText) = components[6] {
            let numRuns = annotatedText.runs.count
            XCTAssertEqual(numRuns, 5)
        } else {
            XCTFail("Expected .example")
        }

        if case let .headline(text, level) = components[7] {
            XCTAssertEqual(text, "Example of a special component")
            XCTAssertEqual(level, .headline3)
        } else {
            XCTFail("Expected .headline")
        }

        if case let .text(content) = components[8] {
            XCTAssertEqual(content, "We have the following cool component to illustrate the passphrase example.")
        } else {
            XCTFail("Expected .content")
        }

        if case let .passphraseBoxes(words) = components[9] {
            XCTAssertEqual(words, ["apple", "waterfall", "diamond"])
        } else {
            XCTFail("Expected .passphraseBoxes")
        }

        if case let .headline(text, level) = components[10] {
            XCTAssertEqual(text, "Another small header")
            XCTAssertEqual(level, .headline3)
        } else {
            XCTFail("Expected .headline")
        }

        if case let .text(content) = components[11] {
            XCTAssertEqual(content, "Some more text followed by a list and a divider.")
        } else {
            XCTFail("Expected .text")
        }

        if case let .listItem(text) = components[12] {
            XCTAssertEqual(
                text,
                "Lists are fun\nWho would not agree? Especially with items that go over multiple lines."
            )
        } else {
            XCTFail("Expected .listItem")
        }

        if case .divider = components[13] {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .divider")
        }

        if case let .button(firstLine, secondLine, identifier) = components[14] {
            XCTAssertEqual(firstLine, "Click here")
            XCTAssertEqual(secondLine, "Button description")
            XCTAssertEqual(identifier, "button_id_somewhere")
        } else {
            XCTFail("Expected .button")
        }
    }

    func testParseHelpScreenMarkup_invalidButton() {
        let input = """
        BUTTON
        This button here
        is missing its third line
        """

        let parser = HelpScreenMarkupParser(highlightColor: .yellow)
        XCTAssertThrowsError(try parser.parseHelpScreenMarkup(markup: input)) { error in
            XCTAssertEqual(error as! HelpScreenMarkupParsingError, HelpScreenMarkupParsingError.invalidButton)
        }
    }

    func testParseHelpScreenMarkup_invalidBlockQuote() {
        let input = """
        BLOCKQUOTE
        This blockquote here
        is missing its third line
        """

        let parser = HelpScreenMarkupParser(highlightColor: .yellow)
        XCTAssertThrowsError(try parser.parseHelpScreenMarkup(markup: input)) { error in
            XCTAssertEqual(error as! HelpScreenMarkupParsingError, HelpScreenMarkupParsingError.invalidBlockQuote)
        }
    }
}
