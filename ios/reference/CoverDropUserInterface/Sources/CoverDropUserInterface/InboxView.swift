import CoverDropCore
import CryptoKit
import GuardianFonts
import SwiftUI

struct InboxView: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var viewModel = InboxViewModel()
    @ObservedObject var conversationViewModel: ConversationViewModel
    @State private var showingDeleteAlert = false

    var body: some View {
        HeaderView(type: .inbox, dismissAction: {
            Task {
                if case let .unlockedSecretData(unlockedData: unlockedData) = SecretDataRepository.shared.secretData {
                    try await SecretDataRepository.shared.lock(data: unlockedData, withSecureEnclave: SecureEnclave.isAvailable)
                }
            }
        }) {
            VStack {
                if let activeConversation = viewModel.activeConversation {
                    activeConversationView(for: activeConversation)
                        .padding(Padding.large)
                }
                if let inactiveConversations = viewModel.inactiveConversations,
                   inactiveConversations.count > 0
                {
                    inactiveConversationsView(for: inactiveConversations)
                }
                Spacer()
                deleteYourMessages
                customDivider()
                footer
            }
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private func messagingTitle(for recipient: JournalistKeyData) -> Text {
        Text("Messaging with")
    }

    @ViewBuilder
    func activeConversationView(for activeConversation: ActiveConversation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                messagingTitle(for: activeConversation.recipient)
                    .textStyle(GuardianHeadlineSmallTextStyle())
                    .foregroundColor(Color.InboxView.activeMessageSubHeaderColor)
                Text(activeConversation.recipient.displayName)
                    .textStyle(TitleStyle())
                    .foregroundColor(Color.InboxView.activeMessageRecipientColor)
                    .onTapGesture {
                        conversationViewModel.messageRecipient = activeConversation.recipient
                        navigation.destination = .viewConversation
                    }
            }
            .padding([.top, .leading, .trailing], Padding.large)
            .padding(.bottom, Padding.small)
            customDivider()
            HStack(alignment: .top, spacing: 2) {
                Image(systemName: "bubble.left")
                    .foregroundColor(Color.InboxView.lastMessageBubbleColor)
                    .padding([.top], Padding.small)

                Text("Last message")
                    .textStyle(MessageDetailTextStyle()).padding([.top], Padding.small)
                Spacer()
                Text(activeConversation.formattedLastMessageUpdated)
                    .textStyle(MessageMetadata())
            }
            .padding([.leading, .trailing], Padding.large)
            .padding([.top, .bottom], Padding.medium)
            if let isExpired = viewModel.activeConversation?.containsExpiringMessages,
               let expiredDate = viewModel.activeConversation?.messageExpiringDate
            {
                customDivider()
                expiredInformationText(expiredDate: expiredDate)
                    .padding([.leading], Padding.medium)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.InboxView.activeMessageBorderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    func inactiveConversationsView(for inactiveConversations: [InactiveConversation]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Previous messages").textStyle(InlineTextButtonStyle())
                .foregroundColor(Color.InboxView.previousMessagesTitleColor)
            customDivider()
            ForEach(inactiveConversations, id: \.recipient) { conversation in
                inactiveConversationsRow(for: conversation)
            }
            customDivider()
        }
        .padding(Padding.large)
    }

    @ViewBuilder
    func inactiveConversationsRow(for inactiveConversation: InactiveConversation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            messagingTitle(for: inactiveConversation.recipient)
                .textStyle(GuardianHeadlineXSmallHeaderTextStyle())
                .foregroundColor(Color.InboxView.previousMessagesSubheaderColor)
            Text(inactiveConversation.recipient.displayName)
                .textStyle(GuardianHeaderTextStyle())
                .foregroundColor(Color.InboxView.previousMessageRecipientColor)
                .onTapGesture {
                    conversationViewModel.messageRecipient = inactiveConversation.recipient
                    navigation.destination = .viewConversation
                }
            if inactiveConversation.containsExpiringMessages != nil,
               let expiredDate = inactiveConversation.messageExpiringDate
            {
                expiredInformationText(expiredDate: expiredDate)
            }
        }
        .padding([.top, .bottom], 10)
        .padding(.leading, Padding.large)
    }

    var deleteYourMessages: some View {
        HStack {
            Button {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color.InboxView.deleteMessageButtonColor)
                    Text("Delete your messages")
                        .textStyle(InlineTextButtonStyle())
                        .foregroundColor(Color.InboxView.deleteMessageButtonColor)
                }
            }
            .accessibilityLabel("Delete your messages")
            .alert("Delete all conversations",
                   isPresented: $showingDeleteAlert,
                   actions: {
                       Button("Yes, delete conversations", role: .destructive) {
                           Task {
                               navigation.destination = .home
                               try await viewModel.deleteAllMessagesAndCurrentSession()
                               if case let .unlockedSecretData(unlockedData: unlockedData) = SecretDataRepository.shared.secretData {
                                   try await SecretDataRepository.shared.lock(data: unlockedData, withSecureEnclave: SecureEnclave.isAvailable)
                               }
                           }
                       }
                       Button("Cancel", role: .cancel) {}
                   }, message: {
                       Text("Deleting all conversations will remove all messages from your device, including pending message to be sent. These cannot be retrieved again. You will also not receive any replies to existing conversations. Would you like to proceed?")
                   })
            Spacer()
        }
        .padding(.leading, Padding.large)
        .padding(.bottom, Padding.medium)
    }

    var footer: some View {
        HStack {
            Text("About SecureMessaging")
                .textStyle(InlineTextButtonStyle())
                .foregroundColor(Color.InboxView.aboutButtonColor)
            Spacer()
            Button("Leave inbox") {
                Task {
                    if case let .unlockedSecretData(unlockedData: unlockedData) = SecretDataRepository.shared.secretData {
                        try await SecretDataRepository.shared.lock(data: unlockedData, withSecureEnclave: SecureEnclave.isAvailable)
                    }
                }
            }
            .buttonStyle(XSmallFilledButtonStyle())
        }
        .padding(.leading, Padding.large)
        .padding(.trailing, Padding.small)
        .padding(.bottom, Padding.medium)
    }

    func expiredInformationText(expiredDate: String) -> some View {
        return Text("\(Image(systemName: "info.circle.fill")) Expiring in \(expiredDate)")
            .foregroundColor(Color.NewMessageView.messageInformationStrokeColor)
            .padding([.top, .trailing, .bottom], Padding.medium)
            .padding([.leading], 0)
    }
}

// swiftlint:disable force_try
struct InboxView_Previews: PreviewProvider {
    static var previews: some View {
        let privateSendingQueueRepo = initSendingQueue()
        let secretDataRepository = SecretDataRepository.shared
        if let messages = try? MessageHelper.loadMessagesFromDeadDrop() {
            secretDataRepository.secretData = messages
        }
        let viewModel = InboxViewModel(secretDataRepository: secretDataRepository)
        return PreviewWrapper(InboxView(viewModel: viewModel, conversationViewModel: ConversationViewModel()))
    }

    static func initSendingQueue() {
        Task {
            if let coverMesage = try? CoverMessage.getCoverMessage() {
                try await PrivateSendingQueueRepository.shared.start(coverMessage: coverMesage)
            }
        }
    }
}
