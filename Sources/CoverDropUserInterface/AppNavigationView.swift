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

    // This is used to track if the user is logging in with a new session
    @ObservedObject var navigation = Navigation.shared

    var body: some View {
        if case .unlockedSecretData = secretDataRepository.secretData {
            InboxStateView()
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
    }
}
