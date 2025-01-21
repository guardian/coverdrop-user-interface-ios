import Combine
import CoverDropCore
import Foundation

@MainActor
class StartCoverDropSessionViewModel: ObservableObject {
    /// Coverdrop services should only be enabled for the user if the public keys are available
    @Published var keysAvailable: Bool = false

    private var keysAvailableSubscriber: AnyCancellable?

    init(publicDataRepository: PublicDataRepository) {
        keysAvailableSubscriber = publicDataRepository.$areKeysAvailable
            .sink { [weak self] newValue in
                self?.keysAvailable = newValue
            }
    }

    func viewHidden() {
        keysAvailableSubscriber?.cancel()
    }

    // We want to check if the users inbox is empty,
    // this only occurs if the user has abandoned the
    // new message process without sending a message
    func isInboxEmpty() -> Bool {
        if case let .unlockedSecretData(data) = SecretDataRepository.shared.secretData {
            return data.unlockedData.messageMailbox.isEmpty
        } else {
            return false
        }
    }
}
