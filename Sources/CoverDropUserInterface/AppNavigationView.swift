import CoverDropCore
import Foundation
import SwiftUI

enum Destination {
    case inbox, newConversation, viewConversation, about,
         privacy, home, onboarding, newPassphrase, login,
         messageSent, deskDetail, selectRecipient
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

    @ObservedObject var securitySuite = SecuritySuite.shared
    @State var verifiedPublicKeysOpt: VerifiedPublicKeys?
    @State var conversationViewModelOpt: ConversationViewModel?

    var body: some View {
        Group {
            if let verifiedPublicKeys = verifiedPublicKeysOpt,
               let conversationViewModel = conversationViewModelOpt,
               coverDropService.isReady
            {
                if !securitySuite.getEffectiveViolationsSet().isEmpty {
                    SecurityAlert()
                } else if case .unlockedSecretData = secretDataRepository.secretData {
                    InboxStateView(verifiedPublicKeys: verifiedPublicKeys, conversationViewModel: conversationViewModel)
                } else {
                    switch navigation.destination {
                    case .about:
                        AboutCoverDropView()
                    case .privacy:
                        PrivacyPolicyView()
                    case .onboarding:
                        OnboardingView()
                    case .newPassphrase:
                        UserNewSessionView()
                    case .login:
                        UserLoginView()
                    case .newConversation:
                        UserLoginView()
                    case .home:
                        StartCoverDropSessionView()
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
