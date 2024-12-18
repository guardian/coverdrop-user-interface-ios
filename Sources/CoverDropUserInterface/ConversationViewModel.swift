import CoverDropCore
import Gzip
import SwiftUI

enum MessageComposeError: Error {
    case textTooLong, invalidCharacter, compressionFailed, unknownError
}

struct MessageData {
    var isCurrentUser: Bool
    var messageText: String
    var dateSent: Date
    var status: MessageStatus
}

@MainActor class ConversationViewModel: ObservableObject {
    @ObservedObject var publicDataRepository = PublicDataRepository.shared
    @ObservedObject var secretDataRepository = SecretDataRepository.shared

    @Published var messageRecipient: JournalistData?
    @Published private(set) var recipients: MessageRecipients?

    @Published var message = ""
    @Published var topic = ""
    @Published var state = State.initial

    public init(verifiedPublicKeys: VerifiedPublicKeys) {
        // We will always set messageRecipient to the supplied one
        // but set it with the defaul journalist if we can get any message reciepients from the keys
        // and the supplied recipient is nil
        state = .loading

        messageRecipient = nil

        // It is a valid scenario that there are no recipients available from the public keys data (ie they have all
        // expired)
        // but we still was the user to be able to view a conversation
        if messageRecipient == nil {
            if let messageRecipientsFromKeys = try? MessageRecipients(
                verifiedPublicKeys: verifiedPublicKeys,
                excludingDefaultRecipient: false
            ) {
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
            let filteredMailbox: [Message] = data.unlockedData.messageMailbox.filter { message in
                switch message {
                case let .incomingMessage(message: messageData):
                    if case let .textMessage(message: incomingMessage) = messageData {
                        return incomingMessage.sender == messageRecipient
                    } else {
                        return false
                    }
                case let .outboundMessage(message: messageData):
                    return messageData.recipient == messageRecipient
                }
            }
            return filteredMailbox.sorted(by: { message1, message2 -> Bool in
                message1.getDate() < message2.getDate()
            })
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
           let lastConversationMessage = currentConversation.last {
            return activeConversation.messages.contains(where: { $0 == lastConversationMessage })
        } else {
            return false
        }
    }

    // This sends a message to the selected message recipient using the covernode public key
    // This handles any errors and updates the view state.
    @MainActor
    func sendMessage() async throws {
        guard let keyHierarchy = try? await publicDataRepository.loadAndVerifyPublicKeys() else {
            state = .error(message: "Unable to load public key")
            return
        }

        guard let messageRecipient else {
            state = .error(message: "No recipient selected")
            return
        }

        let dateSent = DateFunction.currentTime()

        do {
            if case let .unlockedSecretData(data) = secretDataRepository.secretData {
                try await MessageSending.sendMessage(completeMessage(),
                                                     to: messageRecipient,
                                                     verifiedPublicKeys: keyHierarchy,
                                                     unlockedSecretDataRepository: data, dateSent: dateSent)
            }
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

    // We want to disable the send button when the message box is empty,
    // too long, no recipient is selected, or we are in the sending state
    var sendButtonDisabled: Bool {
        switch state {
        case .sending:
            return false
        case _:
            return message.isEmpty || messageIsTooLong || messageRecipient == nil
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

    /// Get the compressed size of the current message, if its greater than zero
    /// return this as a percentage of the total padded message length
    /// otherwise return 0
    var messageLengthProgressPercentage: Result<Double, MessageComposeError> {
        let padToSize = Constants.messagePaddingLen
        do {
            let (_, compressedSize) = try PaddedCompressedString.compressCheckingLength(from: message)
            // Check the size is greater than 0 to avoid returning `Infinity`
            if compressedSize > 0 {
                let percentage = Double(compressedSize) / Double(padToSize) * 100
                return .success(percentage)
            } else {
                return .success(0)
            }
        } catch PaddedCompressedStringError.compressedStringTooLong {
            return .failure(MessageComposeError.textTooLong)
        } catch PaddedCompressedStringError.invaidUTF8StringConversion {
            return .failure(MessageComposeError.invalidCharacter)
        } catch is GzipError {
            return .failure(MessageComposeError.compressionFailed)
        } catch {
            return .failure(MessageComposeError.unknownError)
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

    // This clears the value of `message`, removes the current recipient and locks the secret data.
    // These are coupled to avoid developer error in doing them seperatly.
    // This is called in the various places the user can logout or delete messages.
    public func clearModelDataAndLock(unlockedData: UnlockedSecretDataService) async {
        messageRecipient = nil
        clearMessage()
        try? await SecretDataRepository.shared.lock(unlockedData: unlockedData)
    }

    static let messageDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy HH:mm z"
        return formatter
    }()

    func isMostRecentMessageFromUser() -> Bool {
        switch secretDataRepository.secretData {
        case let .unlockedSecretData(unlockedData: data):
            if let recentMessage: Message = data.unlockedData.messageMailbox.sorted(by: >).first {
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
