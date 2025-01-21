import Foundation
import SwiftUI

enum HelpScreenContent: Error, Equatable {
    case craftMessage
    case faq
    case howSecureMessagingWorks
    case keepingPassphraseSafe
    case privacyPolicy
    case replyExpectations
    case sourceProtection
    case whyWeMadeSecureMessaging

    func resourceName() -> String {
        return switch self {
        case .craftMessage:
            "help_craft_message"
        case .faq:
            "help_faq"
        case .howSecureMessagingWorks:
            "help_how_secure_messaging_works"
        case .keepingPassphraseSafe:
            "help_keeping_passphrase_safe"
        case .privacyPolicy:
            "help_privacy_policy"
        case .replyExpectations:
            "help_reply_expectations"
        case .sourceProtection:
            "help_source_protection"
        case .whyWeMadeSecureMessaging:
            "help_why_we_made_secure_messaging"
        }
    }

    func buttonToContentMapping() -> [String: HelpScreenContent] {
        return switch self {
        case .craftMessage:
            [
                "button_source_protection": HelpScreenContent.sourceProtection
            ]
        case .faq:
            [
                "button_how_secure_messaging_work": HelpScreenContent.howSecureMessagingWorks,
                "button_privacy_policy": HelpScreenContent.privacyPolicy,
                "button_what_to_expect_as_a_reply": HelpScreenContent.replyExpectations
            ]
        case .howSecureMessagingWorks:
            [
                "button_why_we_made_secure_messaging": HelpScreenContent.whyWeMadeSecureMessaging
            ]
        case .keepingPassphraseSafe:
            [:]
        case .privacyPolicy:
            [:]
        case .replyExpectations: [:]
        case .sourceProtection:
            [:]
        case .whyWeMadeSecureMessaging:
            [
                "button_how_secure_messaging_works": HelpScreenContent.howSecureMessagingWorks
            ]
        }
    }
}

enum HelpScreenContentError: Error {
    /// An identifier is provided in the `onClickMapping` but there is no button with that identifier
    case missingButtonIdentifier(identifier: String)

    /// There is a button with that identifier, but it is not a key in the `onClickMapping`
    case danglingButtonIdentifiers(identifier: String)

    /// The markup does not parse correctly
    case badMarkup(markupParsingError: HelpScreenMarkupParsingError)

    /// The resource was not found or is not readable
    case markupFileInvalid(resourceName: String)

    /// Any other error
    case unknown

    func errorMessage() -> String {
        return switch self {
        case let .missingButtonIdentifier(identifier):
            "Missing identifier: \(identifier)"
        case let .danglingButtonIdentifiers(identifier):
            "Dangling identifier: \(identifier)"
        case let .badMarkup(markupParsingError):
            "Bad markup: \(markupParsingError)"
        case let .markupFileInvalid(resourceName):
            "Invalid markup file: \(resourceName)"
        case .unknown:
            "Unknown error"
        }
    }
}

struct HelpView: View {
    @ObservedObject var navigation = Navigation.shared
    @State var content: Result<([HelpScreenComponent], [String: HelpScreenContent]), HelpScreenContentError>

    init(contentVariant: HelpScreenContent) {
        self.init(
            fromResourceName: contentVariant.resourceName(),
            onClickMapping: contentVariant.buttonToContentMapping()
        )
    }

    init(fromResourceName: String, onClickMapping: [String: HelpScreenContent]) {
        do {
            let components = try loadComponentsFromMarkupFile(resourceName: fromResourceName)
            try checkForMissingAndDanglingIdentifiers(components: components, onClickMapping: onClickMapping)
            content = .success((components, onClickMapping))
        } catch let err as HelpScreenContentError {
            self.content = .failure(err)
        } catch {
            content = .failure(HelpScreenContentError.unknown)
        }
    }

    func navigateToHelpVariant(target: HelpScreenContent) {
        navigation.destination = Destination.help(contentVariant: target)
    }

    var body: some View {
        NavigationView {
            HeaderView(type: .about, dismissAction: {
                // TODO: the HelpView can be called from other screens as well, we need to let it
                // know where it should navigate to on dismissal
                navigation.destination = .about
            }) {
                switch self.content {
                case let .success((components, onClickMapping)):
                    ScrollView {
                        let onClickMappingToAction = onClickMapping.mapValues { target in
                            { navigateToHelpVariant(target: target) }
                        }
                        createComponentsColumn(
                            components: components,
                            onClickMapping: onClickMappingToAction
                        ).padding(Padding.medium)
                    }
                case let .failure(error):
                    Text(error.errorMessage())
                }
            }
        }.foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
            .navigationBarHidden(true)
    }
}

/// Reads and parses the given help screen markup and then returns the found list of `HelpScreenComponent`
private func loadComponentsFromMarkupFile(resourceName: String) throws -> [HelpScreenComponent] {
    guard let url = Bundle.module.url(forResource: resourceName, withExtension: "txt") else {
        throw HelpScreenContentError.markupFileInvalid(resourceName: resourceName)
    }
    guard let markup = try? String(contentsOf: url, encoding: .utf8) else {
        throw HelpScreenContentError.markupFileInvalid(resourceName: resourceName)
    }
    do {
        return try HelpScreenMarkupParser().parseHelpScreenMarkup(markup: markup)
    } catch let err as HelpScreenMarkupParsingError {
        throw HelpScreenContentError.badMarkup(markupParsingError: err)
    }
}

private func checkForMissingAndDanglingIdentifiers(components: [HelpScreenComponent], onClickMapping: [String: HelpScreenContent]) throws {
    // We first check for missing or dangling button identifiers
    var allButtonIdentifiers = [String]()
    for component in components {
        if case let .button(_, _, buttonIdentifier) = component {
            allButtonIdentifiers.append(buttonIdentifier)
            // missing identifiers: there is a button with an identifier, but it is not in the mapping
            if !onClickMapping.keys.contains(buttonIdentifier) {
                throw HelpScreenContentError.missingButtonIdentifier(identifier: buttonIdentifier)
            }
        }
    }
    // dangling identifiers: there is an identifier in the mapping, but no button for it
    for onClickMappingKey in onClickMapping.keys where !allButtonIdentifiers.contains(onClickMappingKey) {
        throw HelpScreenContentError.danglingButtonIdentifiers(identifier: onClickMappingKey)
    }
}

/// Creates the help screen UI for the given `HelpScreenComponent` list
private func createComponentsColumn(components: [HelpScreenComponent], onClickMapping: [String: () -> Void]) -> AnyView {
    let vstack = VStack(alignment: .leading, spacing: Padding.medium) {
        ForEach(components.indices, id: \.self) { index in
            let component = components[index]
            switch component {
            case let .headline(text, level):
                HelpHeadline(text: text, level: level)
            case let .text(text):
                Text(text)
            case let .listItem(text):
                HelpList(lines: text.split(separator: "\n").map { String($0) })
            case .divider:
                HelpDivider()
            case .space:
                Spacer().frame(height: Padding.large)
            case let .example(textWithHighlights):
                HelpExample(textWithHighlights: textWithHighlights)
            case let .blockQuote(text, authorName, tagLine):
                HelpBlockQuote(text: text, authorName: authorName, tagLine: tagLine)
            case let .button(firstLine, secondLine, identifier):
                if let action = onClickMapping[identifier] {
                    HelpButton(action: action, firstLine: firstLine, secondLine: secondLine)
                } else {
                    Text("missing button identifier")
                }
            case let .passphraseBoxes(words):
                HelpPassphraseBoxes(words: words)
            }
        }
    }
    return AnyView(vstack)
}
