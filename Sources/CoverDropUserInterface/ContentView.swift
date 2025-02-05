import CoverDropCore
import Foundation
import SwiftUI

enum Destination: Equatable {
    case inbox
    case newConversation
    case viewConversation
    case about
    case home
    case onboarding
    case newPassphrase
    case login
    case messageSent
    case deskDetail
    case selectRecipient
    case help(contentVariant: HelpScreenContent)
}

class Navigation: ObservableObject {
    @Published var destination: Destination = .home

    public static let shared = Navigation()

    private init() {}
}

struct ContentView: View {
    var config: CoverDropConfig
    @ObservedObject var coverDropService: CoverDropService = .shared

    var body: some View {
        Group {
            switch coverDropService.state {
            case .notInitialized, .initializing:
                LoadingView()
            case let .initialized(lib: lib):
                ReadyView(
                    lib: lib,
                    secretDataRepository: lib.publishedSecretDataRepository,
                    conversationViewModel: ConversationViewModel(lib: lib)
                )
            case let .failedToInitialize(reason: reason):
                InitErrorView(error: "error: \(reason)")
            }
        }
    }
}

struct ReadyView: View {
    @ObservedObject var securitySuite = SecuritySuite.shared
    @ObservedObject var lib: CoverDropLibrary
    // Note that if you need to check the state of an enum, it needs it to be
    // a top level object, so we cannot observe lib.secretDataRepository, but can
    // observe secretDataRepository itself.
    @ObservedObject var secretDataRepository: SecretDataRepository
    @ObservedObject var conversationViewModel: ConversationViewModel

    var body: some View {
        if !securitySuite.getEffectiveViolationsSet().isEmpty {
            SecurityAlert()
        } else if case .unlockedSecretData = secretDataRepository.secretData {
            InboxStateView(
                secretDataRepository: lib.publishedSecretDataRepository,
                conversationViewModel: conversationViewModel,
                lib: lib
            )
        } else {
            NonLoggedInNavigationView(lib: lib)
        }
    }
}

struct NonLoggedInNavigationView: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var lib: CoverDropLibrary

    var body: some View {
        switch navigation.destination {
        case .about:
            AboutCoverDropView()
        case .onboarding:
            OnboardingView()
        case .newPassphrase:
            UserNewSessionView(
                passphraseWordCount: lib.config.passphraseWordCount,
                viewModel: UserNewSessionViewModel(lib: lib)
            )
        case .login, .newConversation:
            UserContinueSessionView(viewModel: UserContinueSessionViewModel(lib: lib))
        case .home:
            StartCoverDropSessionView(
                publicDataRepository: lib.publishedPublicDataRepository
            )
        case let .help(contentVariant):
            // This switch might appear unneccessary. However, the Navigation object will not correctly
            // invalid the HelpView if we do not split into separate code paths...
            switch contentVariant {
            case .craftMessage:
                HelpView(contentVariant: .craftMessage)
            case .faq:
                HelpView(contentVariant: .faq)
            case .howSecureMessagingWorks:
                HelpView(contentVariant: .howSecureMessagingWorks)
            case .keepingPassphraseSafe:
                HelpView(contentVariant: .keepingPassphraseSafe)
            case .privacyPolicy:
                HelpView(contentVariant: .privacyPolicy)
            case .replyExpectations:
                HelpView(contentVariant: .replyExpectations)
            case .sourceProtection:
                HelpView(contentVariant: .sourceProtection)
            case .whyWeMadeSecureMessaging:
                HelpView(contentVariant: .whyWeMadeSecureMessaging)
            }
        case _:
            StartCoverDropSessionView(
                publicDataRepository: lib.publishedPublicDataRepository
            )
        }
    }
}
