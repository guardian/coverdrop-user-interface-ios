import CoverDropCore
import SwiftUI

struct InboxView: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var inboxViewModel: InboxViewModel
    @ObservedObject var conversationViewModel: ConversationViewModel
    @State private var showingDeleteAlert = false

    var body: some View {
        HeaderView(type: .inbox, dismissAction: {
            Task {
                await conversationViewModel.clearModelDataAndLock()

                navigation.destination = .home
            }
        }) {
            VStack {
                if let activeConversation = inboxViewModel.activeConversation {
                    activeConversationView(for: activeConversation)
                        .padding(Padding.large)
                }
                if let inactiveConversations = inboxViewModel.inactiveConversations,
                   inactiveConversations.count > 0 {
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
    private func messagingTitle() -> Text {
        Text("Messaging with")
    }

    @ViewBuilder
    func activeConversationView(for activeConversation: ActiveConversation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                messagingTitle()
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
            if inboxViewModel.activeConversation?.containsExpiringMessages != nil,
               let expiredDate = inboxViewModel.activeConversation?.messageExpiringDate {
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
            Text("Previous messages").textStyle(InlineButtonTextStyle())
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
            messagingTitle()
                .textStyle(GuardianHeadlineXSmallHeaderTextStyle())
                .foregroundColor(Color.InboxView.previousMessagesSubheaderColor)
            Text(inactiveConversation.recipient.displayName)
                .textStyle(GuardianHeaderTextStyle())
                .foregroundColor(Color.InboxView.previousMessageRecipientColor)
                .onTapGesture {
                    conversationViewModel.messageRecipient = inactiveConversation.recipient
                    navigation.destination = .viewConversation
                }
            if inactiveConversation.containsExpiringMessages,
               let expiredDate = inactiveConversation.messageExpiringDate {
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
                        .textStyle(InlineButtonTextStyle())
                        .foregroundColor(Color.InboxView.deleteMessageButtonColor)
                }
            }
            .accessibilityLabel("Delete your messages")
            .alert("Delete all conversations?",
                   isPresented: $showingDeleteAlert,
                   actions: {
                       Button("Yes, delete conversations", role: .destructive) {
                           Task {
                               navigation.destination = .home
                               try? await inboxViewModel.deleteAllMessagesAndCurrentSession(
                                   conversationViewModel: conversationViewModel
                               )
                           }
                       }
                       Button("Cancel", role: .cancel) {}
                   }, message: {
                       Text(
                           """
                           Deleting all conversations will remove all messages from your device.
                           This cannot be undone. Would you like to proceed?
                           """
                       )
                   })
            Spacer()
        }
        .padding(.leading, Padding.large)
        .padding(.bottom, Padding.medium)
    }

    var footer: some View {
        HStack {
            Text("About SecureMessaging")
                .textStyle(InlineButtonTextStyle())
                .foregroundColor(Color.InboxView.aboutButtonColor)
            Spacer()
            Button("Leave inbox") {
                Task {
                    await conversationViewModel.clearModelDataAndLock()
                    navigation.destination = .home
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
