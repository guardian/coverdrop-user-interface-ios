import CoverDropCore
import Foundation
import SwiftUI

enum Destination: Equatable {
    case inbox
    case newConversation
    case viewConversation
    case about
    case privacy
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

struct AppNavigationView: View {
    @ObservedObject var secretDataRepository = SecretDataRepository.shared
    @ObservedObject var coverDropService: CoverDropServices = .shared
    // This is used to track if the user is logging in with a new session
    @ObservedObject var navigation = Navigation.shared
    var config: CoverDropConfig

    @ObservedObject var securitySuite = SecuritySuite.shared
    @State var verifiedPublicKeysOpt: VerifiedPublicKeys?
    @State var conversationViewModelOpt: ConversationViewModel?

    var body: some View {
        Group {
            if let verifiedPublicKeys = verifiedPublicKeysOpt,
               let conversationViewModel = conversationViewModelOpt,
               coverDropService.isReady {
                if !securitySuite.getEffectiveViolationsSet().isEmpty {
                    SecurityAlert()
                } else if case .unlockedSecretData = secretDataRepository.secretData {
                    InboxStateView(
                        verifiedPublicKeys: verifiedPublicKeys,
                        conversationViewModel: conversationViewModel,
                        config: config
                    )
                } else {
                    switch navigation.destination {
                    case .about:
                        AboutCoverDropView()
                    case .privacy:
                        PrivacyPolicyView()
                    case .onboarding:
                        OnboardingView()
                    case .newPassphrase:
                        UserNewSessionView(config: config)
                    case .login:
                        UserLoginView(config: config)
                    case .newConversation:
                        UserLoginView(config: config)
                    case .home:
                        StartCoverDropSessionView()
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
                        StartCoverDropSessionView()
                    }
                }
            } else {
                LoadingView()
                    .onAppear {
                        Task {
                            let myVerifiedPublicKeys = try await PublicDataRepository.shared.loadAndVerifyPublicKeys()
                            self.verifiedPublicKeysOpt = myVerifiedPublicKeys
                            self.conversationViewModelOpt = .init(verifiedPublicKeys: myVerifiedPublicKeys)
                        }
                    }
            }
        }
    }
}
