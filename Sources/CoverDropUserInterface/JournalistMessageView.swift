import CoverDropCore
import CryptoKit
import SwiftUI

enum MessageError: Error {
    case failedToLoad
}

struct JournalistMessageView: View {
    @ObservedObject var inboxViewModel = InboxViewModel()
    @ObservedObject var navigation = Navigation.shared
    @StateObject var messageViewModel: ConversationViewModel

    // by default we want to make the user have to choose to send another message
    @State var alreadySentMessage: Bool = false

    var journalist: JournalistKeyData

    init(journalist: JournalistKeyData, viewModel: ConversationViewModel) {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.backgroundColor = UIColor(Color.JournalistNewMessageView.navigationBarBackgroundColor)
        UIScrollView.appearance().backgroundColor = UIColor(Color.JournalistNewMessageView.scrollviewBackgroundColor)
        self.journalist = journalist
        UITextView.appearance().textContainerInset =
            UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        _messageViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HeaderView(type: .viewConversation, dismissAction: {
            Task {
                if case let .unlockedSecretData(unlockedData: unlockedData) = SecretDataRepository.shared.secretData {
                    try await SecretDataRepository.shared.saveMessages(data: unlockedData, withSecureEnclave: SecureEnclave.isAvailable)
                    navigation.destination = .inbox
                    messageViewModel.messageRecipient = nil
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                messageListView()
                VStack {
                    if !self.messageViewModel.isCurrentConversationActive(maybeActiveConversation: inboxViewModel.activeConversation) {
                        viewingInactiveConversation()
                    } else if self.messageViewModel.isMostRecentMessageFromUser()
                        && alreadySentMessage
                    {
                        messageSendView()
                    } else {
                        if let messageRecipient = self.messageViewModel.messageRecipient,
                           let key = messageRecipient.getMessageKey(),
                           let config = PublicDataRepository.appConfig
                        {
                            if key.isExpired(now: config.currentTime()) {
                                expiredKeysMessage(recipent: messageRecipient)
                            } else {
                                chooseToSentAnotherMessage()
                            }
                        } else {
                            messageSendView()
                        }
                    }
                }.padding(Padding.medium)
            }
            .navigationBarTitle("Secure chat with \(journalist.displayName)", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }

    private func messageListView() -> some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    VStack(alignment: .center) {
                        if let recipient = self.messageViewModel.messageRecipient {
                            Text("\(Image(systemName: "lock.fill")) This is a secure conversation with \(recipient.displayName)").bold()
                        }
                    }
                    switch self.messageViewModel.state {
                    case .initial, .loading, .ready, .sending:
                        switch self.messageViewModel.secretDataRepository.secretData {
                        case let .unlockedSecretData(unlockedData: data):
                            ForEach(messageViewModel.currentConversation.indices, id: \.self) { index in
                                switch messageViewModel.currentConversation[index] {
                                // We have a seperate view for incoming and outbound messages
                                // because outbound messages have message statuses which cannot be observed
                                // when inside an enum
                                case let .outboundMessage(message: message):
                                    OutboundMessageView(outboundMessage: message, id: index)
                                case let .incomingMessage(message: message):
                                    IncomingMessageView(message: message, id: index)
                                }
                            }.onChange(of: data.messageMailbox.count) { _ in
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
                .foregroundColor(Color.JournalistNewMessageView.messageListForegroudnColor)
            // This spacer keeps the middle pane in full height
            Spacer()
        }
    }

    func chooseToSentAnotherMessage() -> some View {
        return VStack {
            Text("Your message has been sent. We recommend waiting for a response before you send another message.").textStyle(UserNotificationTextStyle())
            Button("Send a new message") {
                self.alreadySentMessage = true
            }.buttonStyle(SecondaryButtonStyle(isDisabled: false))
                .accessibilityLabel("Send a new message")
        }.foregroundColor(Color.ComposeMessageTextStyle.foregroundColor)
    }

    func viewingInactiveConversation() -> some View {
        return InformationView(viewType: .info, title: "This conversation has been closed", message: "Go to your active conversation to send a message.")
    }

    func expiredKeysMessage(recipent: JournalistKeyData) -> some View {
        return InformationView(viewType: .info, title: "\(recipent.displayName) is currently unavailable.", message: "Check your internet connection or try again later.")
    }

    func messageSendView() -> some View {
        return VStack {
            TextEditor(text: $messageViewModel.message)
                .style(ComposeMessageTextStyle())
                .frame(minHeight: 60, maxHeight: 60)
            Button("Send") {
                Task {
                    try? await messageViewModel.sendMessage()
                    messageViewModel.clearMessage()
                }
            }.disabled(messageViewModel.sendButtonDisabled)
                .buttonStyle(PrimaryButtonStyle(isDisabled: messageViewModel.sendButtonDisabled))
        }
    }

    private func scrollToLastMessage(scrollViewProxy: ScrollViewProxy) {
        switch messageViewModel.secretDataRepository.secretData {
        case let .unlockedSecretData(unlockedData: data):
            let unwrappedId = data.messageMailbox.count - 1
            withAnimation {
                scrollViewProxy.scrollTo(unwrappedId, anchor: .bottom)
            }
        case _:
            return
        }
    }
}

struct JournalistMessageView_Previews: PreviewProvider {
    @MainActor struct Container: View {
        @State var viewModel = getViewModel(recipient: PublicKeysHelper.shared.testDefaultJournalist!)
        @State var anotherViewModel = getViewModel(recipient: PublicKeysHelper.shared.getTestDesk!)
        let privateSendingQueueRepo = initSendingQueue()

        @MainActor var body: some View {
            JournalistMessageView(journalist: PublicKeysHelper.shared.testDefaultJournalist!, viewModel: viewModel)
            JournalistMessageView(journalist: PublicKeysHelper.shared.getTestDesk!, viewModel: anotherViewModel)
        }
    }

    static func getViewModel(recipient: JournalistKeyData) -> ConversationViewModel {
        do {
            let model = ConversationViewModel(verifiedPublicKeys: PublicKeysHelper.shared.testKeys, recipient: recipient)

            model.secretDataRepository.secretData = try MessageHelper.addMessagesToInbox()
            return model
        } catch {
            return ConversationViewModel(verifiedPublicKeys: PublicKeysHelper.shared.testKeys, recipient: recipient)
        }
    }

    static func initSendingQueue() {
        Task {
            if let coverMesage = try? CoverMessage.getCoverMessage() {
                try await PrivateSendingQueueRepository.shared.start(coverMessage: coverMesage)
            }
        }
    }

    static var previews: some View {
        Container()
    }
}
