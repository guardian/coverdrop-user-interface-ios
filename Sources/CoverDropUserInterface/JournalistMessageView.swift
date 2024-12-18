import CoverDropCore
import SwiftUI

enum MessageError: Error {
    case failedToLoad
}

struct JournalistMessageView: View {
    @ObservedObject var inboxViewModel: InboxViewModel
    @ObservedObject var navigation = Navigation.shared
    @StateObject var conversationViewModel: ConversationViewModel
    var config: CoverDropConfig
    var verifiedPublicKeys: VerifiedPublicKeys

    // by default we want to make the user have to choose to send another message
    @State var alreadySentMessage: Bool = false

    var journalist: JournalistData

    init(
        journalist: JournalistData,
        conversationViewModel: ConversationViewModel,
        verifiedPublicKeys: VerifiedPublicKeys,
        config: CoverDropConfig
    ) {
        self.config = config
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.backgroundColor = UIColor(Color.JournalistNewMessageView.navigationBarBackgroundColor)
        UIScrollView.appearance().backgroundColor = UIColor(Color.JournalistNewMessageView.scrollviewBackgroundColor)
        self.journalist = journalist
        UITextView.appearance().textContainerInset =
            UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        _conversationViewModel = StateObject(wrappedValue: conversationViewModel)
        self.verifiedPublicKeys = verifiedPublicKeys
        inboxViewModel = InboxViewModel(config: config)
    }

    var body: some View {
        HeaderView(type: .viewConversation, dismissAction: {
            Task {
                navigation.destination = .inbox
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                let recipientOpt = conversationViewModel.messageRecipient
                if let recipient = recipientOpt {
                    messageListView()
                    messageComposeView(recipient: recipient)
                }
            }
            .navigationBarTitle("Secure chat with \(journalist.displayName)", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }

    private func messageComposeView(recipient: JournalistData) -> some View {
        @State var expired = false
        return VStack {
            let inactive = !self.conversationViewModel
                .isCurrentConversationActive(maybeActiveConversation: inboxViewModel.activeConversation)
            let isMostRecentMessageFromUser = self.conversationViewModel.isMostRecentMessageFromUser()

            if expired {
                expiredKeysMessage(recipient: recipient)
            } else if inactive {
                viewingInactiveConversation()
            } else if isMostRecentMessageFromUser && !alreadySentMessage {
                chooseToSentAnotherMessage()
            } else {
                messageSendView()
            }

        }.onAppear {
            Task {
                expired = await isCurrentKeyExpired(recipient: recipient)
            }
        }
    }

    func isCurrentKeyExpired(recipient: JournalistData) async -> Bool {
        if let currentKey = await PublicDataRepository.getLatestMessagingKey(recipientId: recipient.recipientId) {
            return currentKey.isExpired(now: DateFunction.currentKeysPublishedTime())
        }
        return false
    }

    private func messageListView() -> some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    VStack(alignment: .center) {
                        if let recipient = self.conversationViewModel.messageRecipient {
                            let headerMessage = "This is a secure conversation with \(recipient.displayName)"
                            Text(
                                "\(Image(systemName: "lock.fill")) \(headerMessage)"
                            )
                            .bold()
                        }
                    }
                    switch self.conversationViewModel.state {
                    case .initial, .loading, .ready, .sending:
                        switch self.conversationViewModel.secretDataRepository.secretData {
                        case let .unlockedSecretData(unlockedData: data):
                            ForEach(conversationViewModel.currentConversation.indices, id: \.self) { index in
                                switch conversationViewModel.currentConversation[index] {
                                // We have a seperate view for incoming and outbound messages
                                // because outbound messages have message statuses which cannot be observed
                                // when inside an enum
                                case let .incomingMessage(message: incomingMessage):
                                    if case let .textMessage(message: incomingTextMessage) = incomingMessage {
                                        IncomingMessageView(message: incomingTextMessage, id: index)
                                    } else {
                                        EmptyView()
                                    }
                                case let .outboundMessage(message: outboundMessage):
                                    OutboundMessageView(outboundMessage: outboundMessage, id: index)
                                }
                            }.onChange(of: data.unlockedData.messageMailbox.count) { _ in
                                scrollToLastMessage(scrollViewProxy: scrollViewProxy)
                            }.onAppear {
                                scrollToLastMessage(scrollViewProxy: scrollViewProxy)
                            }
                        case _:
                            EmptyView()
                        }
                    case let .error(error):
                        Text("Error: \(error)")
                    }
                }
            }.padding(Padding.medium)
                .background(Color.JournalistNewMessageView.messageListBackgroundColor)
                .foregroundColor(Color.JournalistNewMessageView.messageListForegroundColor)
            // This spacer keeps the middle pane in full height
            Spacer()
        }
    }

    func chooseToSentAnotherMessage() -> some View {
        return VStack {
            Text(
                """
                Your message has been sent. \
                We recommend that you exit Secure Messaging and wait for a response before you send another message.
                """
            )
            .textStyle(UserNotificationTextStyle())
            Button("Send a new message") {
                self.alreadySentMessage = true
            }.buttonStyle(SecondaryButtonStyle(isDisabled: false))
                .accessibilityLabel("Send a new message")
        }.foregroundColor(Color.ComposeMessageTextStyle.foregroundColor)
            .padding(Padding.medium)
    }

    func viewingInactiveConversation() -> some View {
        return InformationView(
            viewType: .info,
            title: "This conversation has been closed",
            message: "Go to your active conversation to send a message."
        ).padding(Padding.medium)
    }

    func expiredKeysMessage(recipient: JournalistData) -> some View {
        return InformationView(
            viewType: .info,
            title: "\(recipient.displayName) is currently unavailable.",
            message: "Check your internet connection or try again later."
        )
        .padding(Padding.medium)
    }

    func messageSendView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            MessageLengthProgressView(
                messageLengthProgressPercentage: conversationViewModel.messageLengthProgressPercentage
            )
            .padding([.horizontal], Padding.medium)
            TextEditor(text: $conversationViewModel.message)
                .style(ComposeMessageTextStyle())
                .frame(minHeight: 60, maxHeight: 80)
                .padding(Padding.medium)
                .accessibilityLabel("Compose your message")

            Button("Send") {
                Task {
                    try? await conversationViewModel.sendMessage()
                    conversationViewModel.clearMessage()
                }
            }.disabled(conversationViewModel.sendButtonDisabled)
                .buttonStyle(PrimaryButtonStyle(isDisabled: conversationViewModel.sendButtonDisabled))
                .padding([.horizontal], Padding.medium)
                .accessibilityLabel("Send")
        }
    }

    private func scrollToLastMessage(scrollViewProxy: ScrollViewProxy) {
        switch conversationViewModel.secretDataRepository.secretData {
        case let .unlockedSecretData(unlockedData: data):
            let unwrappedId = data.unlockedData.messageMailbox.count - 1
            withAnimation {
                scrollViewProxy.scrollTo(unwrappedId, anchor: .bottom)
            }
        case _:
            return
        }
    }
}
