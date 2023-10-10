import CoverDropCore
import SwiftUI

struct MessageData {
    var isCurrentUser: Bool
    var messageText: String
    var dateSent: Date
    var status: MessageStatus
}

@MainActor class ConversationViewModel: ObservableObject, MessageSending {
    @ObservedObject var publicDataRepository = PublicDataRepository.shared
    @ObservedObject var secretDataRepository = SecretDataRepository.shared

    @Published var messageRecipient: JournalistKeyData?
    @Published private(set) var recipients: MessageRecipients?

    @Published var message = ""
    @Published var topic = ""
    @Published var state = State.initial

    init(verifiedPublicKeys: VerifiedPublicKeys? = PublicDataRepository.shared.verifiedPublicKeysData, recipient: JournalistKeyData? = nil) {
        // We will always set messageRecipient to the supplied one
        // but set it with the defaul journalist if we can get any message reciepients from the keys
        // and the supplied recipient is nil
        state = .loading

        messageRecipient = recipient

        // It is a valid scenario that there are no recipients available from the public keys data (ie they have all expired)
        // but we still was the user to be able to view a conversation
        if messageRecipient == nil {
            if let messageRecipientsFromKeys = try? MessageRecipients(verifiedPublicKeys: verifiedPublicKeys, excludingDefaultRecipient: false) {
                recipients = messageRecipientsFromKeys
                if messageRecipientsFromKeys.defaultRecipient != nil {
                    messageRecipient = messageRecipientsFromKeys.defaultRecipient
                }
            } else {
                messageRecipient = recipients?.journalists.first
            }
        }
        state = .ready
    }

    enum State: Equatable {
        case initial, loading, ready, sending
        case error(message: String)
    }

    // This returns the current conversation as a list of `Message` based on the message recipient
    var currentConversation: [Message] {
        switch secretDataRepository.secretData {
        case let .unlockedSecretData(unlockedData: data):
            return data.messageMailbox.filter { message in
                switch message {
                case let .incomingMessage(message: messageData):
                    return messageData.sender == messageRecipient
                case let .outboundMessage(message: messageData):
                    return messageData.recipient == messageRecipient
                }
            }
        case _:
            return []
        }
    }

    // This checks to see if the current conversation in active or inactive
    // We currenly only allow the user to reply to the active conversation, which restricts
    // the user to having one conversation at the time.
    // We check to see if the most recent message from the current conversation is in the active conversation

    func isCurrentConversationActive(maybeActiveConversation: ActiveConversation?) -> Bool {
        if let activeConversation = maybeActiveConversation,
           let lastConversationMessage = currentConversation.last
        {
            return activeConversation.messages.contains(where: { $0 == lastConversationMessage })
        } else {
            return false
        }
    }

    // This sends a message to the selected message recipient using the covernode public key
    // This handles any errors and updates the view state.
    @MainActor
    func sendMessage() async throws {
        guard let keyHierarchy = publicDataRepository.verifiedPublicKeysData
        else {
            state = .error(message: "Unable to load public key")
            return
        }

        guard let messageRecipient else {
            state = .error(message: "No recipient selected")
            return
        }

        guard let dateSent = PublicDataRepository.appConfig?.currentTime() else {
            state = .error(message: "Cannot get config")
            return
        }

        do {
            try await sendMessage(completeMessage(),
                                  to: messageRecipient,
                                  verifiedPublicKeys: keyHierarchy,
                                  secretDataRepository: secretDataRepository, dateSent: dateSent)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    private func completeMessage() -> String {
        if topic.isEmpty {
            return message
        } else {
            return topic + "\n\n" + message
        }
    }

    // We want to disable the send button when the message box is empty or we are in the sending state
    var sendButtonDisabled: Bool {
        switch state {
        case .sending:
            return false
        case _:
            return message.isEmpty
        }
    }

    var messageIsTooLong: Bool {
        do {
            try PaddedCompressedString.compressCheckingLength(from: completeMessage())
            return false
        } catch PaddedCompressedStringError.compressedStringTooLong {
            return true
        } catch {
            return false
        }
    }

    // This clears the value of `message`
    // Used to clear the TextEditor input box when a message is sent
    // Or when the users first focuses on the input
    func clearMessage() {
        message = ""
        topic = ""
        state = .ready
    }

    static let messageDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy HH:mm z"
        return formatter
    }()

    func isMostRecentMessageFromUser() -> Bool {
        switch secretDataRepository.secretData {
        case let .unlockedSecretData(unlockedData: data):
            if let recentMessage: Message = data.messageMailbox.sorted(by: >).first {
                switch recentMessage {
                case .outboundMessage:
                    return true
                case _:
                    return false
                }
            } else {
                return false
            }
        case _:
            return false
        }
    }

    static func getIncomingMessageData(message: IncomingMessageData) -> MessageData {
        return MessageData(isCurrentUser: false, messageText: message.messageText,
                           dateSent: message.dateReceived, status: message.expiredStatus)
    }

    static func getOutboundMessageData(message: OutboundMessageData) -> MessageData {
        return MessageData(isCurrentUser: true, messageText: message.messageText,
                           dateSent: message.dateQueued, status: message.expiredStatus)
    }
}
