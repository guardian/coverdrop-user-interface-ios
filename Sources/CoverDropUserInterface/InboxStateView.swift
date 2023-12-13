import CoverDropCore
import Foundation
import SwiftUI

struct InboxStateView: View {
    @ObservedObject var secretDataRepository = SecretDataRepository.shared
    var body: some View {
        if case let .unlockedSecretData(unlockedData: secretData) = secretDataRepository.secretData {
            UnlockedSecretDataStateSwitcher(unlockedSecretData: secretData)
        }
    }
}

// This view chooses the view to display when the user is logged in.
// This exta level of indirection is needed to allow us to observe changes in a value that is wrapped in
// an enum state, so we first need to establish we are in the `.unlockedSecretData` enum variant, and then pass
// this `UnlockedSecretData` into a new view so that we can observe changes to the mailbox
struct UnlockedSecretDataStateSwitcher: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var unlockedSecretData: UnlockedSecretData
    @ObservedObject var conversationViewModel = ConversationViewModel(verifiedPublicKeys: PublicDataRepository.shared.verifiedPublicKeysData)

    var body: some View {
        if unlockedSecretData.messageMailbox.isEmpty {
            if case .newConversation = navigation.destination {
                // This scenario is when the user has logged in for the first time
                // after creating a new session and has never sent a message
                NewMessageView(viewModel: conversationViewModel, inboxIsEmpty: false)
            } else if case .login = navigation.destination {
                // This scenario is when the user had abandoned sending their initial message, but had created a
                // session, and is re-logging in
                NewMessageView(viewModel: conversationViewModel, inboxIsEmpty: true)
            }
        } else if !unlockedSecretData.messageMailbox.isEmpty {
            if case .newConversation = navigation.destination {
                // This scenario is when the user has just sent their first message for this session (after the new message flow)
                MessageSentView()
            } else if case .viewConversation = navigation.destination {
                if conversationViewModel.messageRecipient != nil {
                    // This scenario is viewing an existing conversation
                    JournalistMessageView(journalist: conversationViewModel.messageRecipient!, viewModel: conversationViewModel)
                } else {
                    InboxView(conversationViewModel: conversationViewModel)
                }
            } else if case .inbox = navigation.destination {
                // This scenario is when the user has logged in
                InboxView(conversationViewModel: conversationViewModel)
            } else {
                InboxView(conversationViewModel: conversationViewModel)
            }
        }
    }
}
