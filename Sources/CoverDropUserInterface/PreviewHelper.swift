import CoverDropCore
import Foundation

enum PreviewHelper {
    @MainActor static func getConversationViewModel(recipient: JournalistData) -> ConversationViewModel {
        do {
            ConversationViewModel.shared.publicDataRepository.verifiedPublicKeysData = PublicKeysHelper.shared.testKeys
            ConversationViewModel.shared.messageRecipient = recipient
            ConversationViewModel.shared.secretDataRepository.secretData = try MessageHelper.addMessagesToInbox()
            return ConversationViewModel.shared

        } catch {
            return ConversationViewModel.shared
        }
    }
}
