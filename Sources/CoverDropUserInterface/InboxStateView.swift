import Combine
import CoverDropCore
import Foundation
import SwiftUI

struct InboxStateView: View {
    @ObservedObject var secretDataRepository = SecretDataRepository.shared
    var verifiedPublicKeys: VerifiedPublicKeys
    var conversationViewModel: ConversationViewModel
    var config: ConfigType

    var body: some View {
        if case let .unlockedSecretData(unlockedData: secretData) = secretDataRepository.secretData {
            UnlockedSecretDataStateSwitcher(unlockedSecretData: secretData, conversationViewModel: conversationViewModel, verifiedPublicKeys: verifiedPublicKeys, config: config)
        }
    }
}

// This view chooses the view to display when the user is logged in.
// This exta level of indirection is needed to allow us to observe changes in a value that is wrapped in
// an enum state, so we first need to establish we are in the `.unlockedSecretData` enum variant, and then pass
// this `UnlockedSecretData` into a new view so that we can observe changes to the mailbox
struct UnlockedSecretDataStateSwitcher: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var unlockedSecretData: UnlockedSecretDataService
    @ObservedObject var conversationViewModel: ConversationViewModel
    var verifiedPublicKeys: VerifiedPublicKeys
    var config: ConfigType

    var body: some View {
        if unlockedSecretData.unlockedData.messageMailbox.isEmpty {
            if case .newConversation = navigation.destination {
                // This scenario is when the user has logged in for the first time
                // after creating a new session and has never sent a message
                NewMessageView(viewModel: conversationViewModel, inboxIsEmpty: false)
            } else if case .login = navigation.destination {
                // This scenario is when the user had abandoned sending their initial message, but had created a
                // session, and is re-logging in
                NewMessageView(viewModel: conversationViewModel, inboxIsEmpty: true)
            }
        } else if !unlockedSecretData.unlockedData.messageMailbox.isEmpty {
            if case .newConversation = navigation.destination {
                // This scenario is when the user has just sent their first message for this session (after the new message flow)
                MessageSentView(conversationViewModel: conversationViewModel)
            } else if case .viewConversation = navigation.destination {
                if conversationViewModel.messageRecipient != nil {
                    // This scenario is viewing an existing conversation
                    JournalistMessageView(journalist: conversationViewModel.messageRecipient!, conversationViewModel: conversationViewModel, verifiedPublicKeys: verifiedPublicKeys, config: config)
                } else {
                    InboxView(inboxViewModel: InboxViewModel(config: config), conversationViewModel: conversationViewModel, verifiedPublicKeys: verifiedPublicKeys)
                }
            } else if case .inbox = navigation.destination {
                // This scenario is when the user has logged in
                InboxView(inboxViewModel: InboxViewModel(config: config), conversationViewModel: conversationViewModel, verifiedPublicKeys: verifiedPublicKeys)
            } else {
                InboxView(inboxViewModel: InboxViewModel(config: config), conversationViewModel: conversationViewModel, verifiedPublicKeys: verifiedPublicKeys)
            }
        }
    }
}
