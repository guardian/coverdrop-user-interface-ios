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
    var config: ConfigType?

    // by default we want to make the user have to choose to send another message
    @State var alreadySentMessage: Bool = false

    var journalist: JournalistKeyData

    init(journalist: JournalistKeyData, viewModel: ConversationViewModel, config: ConfigType? = PublicDataRepository.appConfig) {
        self.config = config
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
                                && alreadySentMessage {
                        messageSendView()
                    } else {
                        if let messageRecipient = self.messageViewModel.messageRecipient,
                           let key = messageRecipient.getMessageKey(),
                           let config = config {
                            if key.isExpired(now: config.currentKeysPublishedTime()) {
                                expiredKeysMessage(recipent: messageRecipient)
                            } else if alreadySentMessage {
                                messageSendView()
                            } else {
                                chooseToSentAnotherMessage()
                            }
                        } else {
                            messageSendView()
                        }
                    }
                }
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
                                case let .incomingMessage(message: incomingMessage):
                                    if case let .textMessage(message: incomingTextMessage) = incomingMessage {
                                        IncomingMessageView(message: incomingTextMessage, id: index)
                                    } else {
                                        EmptyView()
                                    }
                                case let .outboundMessage(message: outboundMessage):
                                    OutboundMessageView(outboundMessage: outboundMessage, id: index)
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
            .foregroundColor(Color.JournalistNewMessageView.messageListForegroundColor)
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
        .padding(Padding.medium)
    }

    func viewingInactiveConversation() -> some View {
        return InformationView(viewType: .info, title: "This conversation has been closed", message: "Go to your active conversation to send a message.").padding(Padding.medium)
    }

    func expiredKeysMessage(recipent: JournalistKeyData) -> some View {
        return InformationView(viewType: .info, title: "\(recipent.displayName) is currently unavailable.", message: "Check your internet connection or try again later.")
            .padding(Padding.medium)
    }

    func messageSendView() -> some View {
        return VStack {
            messageLengthView()
            TextEditor(text: $messageViewModel.message)
                .style(ComposeMessageTextStyle())
                .frame(minHeight: 60, maxHeight: 80)
                .padding(Padding.medium)
                .accessibilityLabel("Compose your message")

            Button("Send") {
                Task {
                    try? await messageViewModel.sendMessage()
                    messageViewModel.clearMessage()
                }
            }.disabled(messageViewModel.sendButtonDisabled)
            .buttonStyle(PrimaryButtonStyle(isDisabled: messageViewModel.sendButtonDisabled))
            .padding([.horizontal], Padding.medium)
        }
    }

    func messageLengthView() -> some View {
        return VStack {
            switch messageViewModel.messageLengthProgressPercentage {
            case let .success(percentage):
                ProgressView(value: percentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.ProgressBarStyle.fillingColor))
            case let .failure(errorType):
                switch errorType {
                case .invalidCharacter:
                    Text("You've entered an invalid character")
                case .textTooLong:
                    Text("Message limit reached")
                    Text("Please shorten your message")
                    ProgressView(value: 100, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.ProgressBarStyle.fullColor))
                case .compressionFailed, .unknownError:
                    Text("Message error, please try again later")
                }
            }
        }.foregroundColor(Color.JournalistNewMessageView.messageListForegroundColor)
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
        let previewConfig = ConfigType.devConfig
        @State var viewModel = getViewModel(recipient: PublicKeysHelper.shared.testDefaultJournalist!)
        @State var anotherViewModel = getViewModel(recipient: PublicKeysHelper.shared.getTestDesk!)
        let privateSendingQueueRepo = initSendingQueue()

        @MainActor var body: some View {
            JournalistMessageView(journalist: PublicKeysHelper.shared.testDefaultJournalist!, viewModel: viewModel, config: previewConfig)
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
            let verifiedPublicKeys = PublicKeysHelper.shared.testKeys
            if let coverMessageFactory = try? PublicDataRepository.getCoverMessageFactory(verifiedPublicKeys: verifiedPublicKeys) {
                try await PrivateSendingQueueRepository.shared.start(coverMessageFactory: coverMessageFactory)
            }
        }
    }

    static var previews: some View {
        Container()
    }
}
