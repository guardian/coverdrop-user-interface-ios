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

struct AppNavigationView: View {
    @ObservedObject var secretDataRepository = SecretDataRepository.shared
    @ObservedObject var coverDropService: CoverDropServices = .shared
    // This is used to track if the user is logging in with a new session
    @ObservedObject var navigation = Navigation.shared
    var config: CoverDropConfig

    @ObservedObject var securitySuite = SecuritySuite.shared
    @State var verifiedPublicKeysOpt: VerifiedPublicKeys?
    @State var conversationViewModelOpt: ConversationViewModel?
    @State var startCoverDropSessionViewModelOpt: StartCoverDropSessionViewModel?
    @State var publicDataRepositoryOpt: PublicDataRepository?

    var body: some View {
        Group {
            if let verifiedPublicKeys = verifiedPublicKeysOpt,
               let conversationViewModel = conversationViewModelOpt,
               let startCoverDropSessionViewModel = startCoverDropSessionViewModelOpt,
               let publicDataRepository = publicDataRepositoryOpt,
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
                    nonLoggedInScreens(
                        verifiedPublicKeys: verifiedPublicKeys,
                        publicDataRepository: publicDataRepository,
                        startCoverDropSessionViewModel: startCoverDropSessionViewModel
                    )
                }
            } else {
                loadingView()
            }
        }
    }

    @ViewBuilder
    func loadingView() -> some View {
        // This is the main entry point into the UI
        // All initialisation of data required for child views is done here
        // Generally the backend will have already got the verified public keys
        // But we check again just in case
        LoadingView()
            .onAppear {
                Task {
                    PublicDataRepository.setup(config)
                    let publicDataRepository = PublicDataRepository.shared
                    let myVerifiedPublicKeys = try await publicDataRepository
                        .loadAndVerifyPublicKeys(config: config)
                    let startCoverDropSessionViewModel = StartCoverDropSessionViewModel(
                        publicDataRepository: publicDataRepository
                    )
                    self.verifiedPublicKeysOpt = myVerifiedPublicKeys
                    self.conversationViewModelOpt = .init(
                        verifiedPublicKeys: myVerifiedPublicKeys,
                        config: self.config
                    )
                    self.publicDataRepositoryOpt = publicDataRepository
                    self.startCoverDropSessionViewModelOpt = startCoverDropSessionViewModel
                }
            }
    }

    @ViewBuilder
    func nonLoggedInScreens(
        verifiedPublicKeys: VerifiedPublicKeys,
        publicDataRepository: PublicDataRepository,
        startCoverDropSessionViewModel: StartCoverDropSessionViewModel
    ) -> some View {
        switch navigation.destination {
        case .about:
            AboutCoverDropView()
        case .onboarding:
            // Text("test")
            OnboardingView()
        case .newPassphrase:
            UserNewSessionView(config: config)
        case .login, .newConversation:
            UserLoginView(userLoginViewModel: UserLoginViewModel(
                config: config,
                verifiedPublicKeys: verifiedPublicKeys
            ))
        case .home:
            StartCoverDropSessionView(
                publicDataRepository: publicDataRepository,
                viewModel: startCoverDropSessionViewModel
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
                publicDataRepository: publicDataRepository,
                viewModel: startCoverDropSessionViewModel
            )
        }
    }
}
