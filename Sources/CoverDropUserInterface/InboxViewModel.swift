import CoverDropCore
import CryptoKit
import SwiftUI

public struct ActiveConversation: Equatable {
    let recipient: JournalistKeyData
    let lastMessageUpdated: Date

    var messages: [Message] = []

    var containsExpiringMessages: Bool {
        return messages.contains(where: { message in
            switch message {
            case let .incomingMessage(message: messageData):
                switch messageData.expiredStatus {
                case .expiring:
                    return true
                case .pendingOrSent:
                    return false
                }
            case let .outboundMessage(message: messageData):
                switch messageData.expiredStatus {
                case .expiring:
                    return true
                case .pendingOrSent:
                    return false
                }
            }
        })
    }

    var messageExpiringDate: String? {
        if let lastMessage = messages.sorted(by: >).last {
            switch lastMessage {
            case let .incomingMessage(message: messageData):
                switch messageData.expiredStatus {
                case let .expiring(time: expiringTime):
                    return expiringTime
                case .pendingOrSent:
                    return nil
                }
            case let .outboundMessage(message: messageData):
                switch messageData.expiredStatus {
                case let .expiring(time: expiringTime):
                    return expiringTime
                case .pendingOrSent:
                    return nil
                }
            }
        }
        return nil
    }

    var formattedLastMessageUpdated: String {
        lastMessageUpdated.formatted(date: .abbreviated, time: .shortened)
    }
}

public struct InactiveConversation: Equatable {
    let recipient: JournalistKeyData
    var messages: [Message] = []

    var containsExpiringMessages: Bool {
        return messages.contains(where: { message in
            switch message {
            case let .incomingMessage(message: messageData):
                switch messageData.expiredStatus {
                case .expiring:
                    return true
                case .pendingOrSent:
                    return false
                }
            case let .outboundMessage(message: messageData):
                switch messageData.expiredStatus {
                case .expiring:
                    return true
                case .pendingOrSent:
                    return false
                }
            }
        })
    }

    var messageExpiringDate: String? {
        if let lastMessage = messages.sorted(by: >).last {
            switch lastMessage {
            case let .incomingMessage(message: messageData):
                switch messageData.expiredStatus {
                case let .expiring(time: expiringTime):
                    return expiringTime
                case .pendingOrSent:
                    return nil
                }
            case let .outboundMessage(message: messageData):
                switch messageData.expiredStatus {
                case let .expiring(time: expiringTime):
                    return expiringTime
                case .pendingOrSent:
                    return nil
                }
            }
        }
        return nil
    }
}

@MainActor
class InboxViewModel: ObservableObject {
    private var mailbox: [Message]? {
        guard case let .unlockedSecretData(unlockedData: data) = secretDataRepository.secretData else { return nil }
        return data.messageMailbox
    }

    var activeConversation: ActiveConversation? {
        InboxViewModel.findActiveConversation(in: mailbox)
    }

    var inactiveConversations: [InactiveConversation]? {
        InboxViewModel.findInactiveMessages(in: mailbox)
    }

    @ObservedObject private var secretDataRepository: SecretDataRepository = .shared

    init(secretDataRepository: SecretDataRepository? = nil) {
        if let secretDataRepository {
            self.secretDataRepository = secretDataRepository
        }
    }

    /// Finds the most recent conversation in a mailbox, and returns an Active Conversation. If there are no messages in the mailbox, this returns nil.
    static func findActiveConversation(in mailbox: [Message]?) -> ActiveConversation? {
        guard let existingMailbox = mailbox else {
            return nil
        }
        // 1. If we only have outbound messages there should just be a single recipient
        // so return the active conversation as the recipient of this message
        let onlyOutbound = existingMailbox.allSatisfy {
            if case .outboundMessage = $0 { return true }
            return false
        }

        if onlyOutbound {
            let messages = existingMailbox.sorted(by: >)
            if let message = messages.first {
                if case let .outboundMessage(data) = message {
                    return ActiveConversation(recipient: data.recipient, lastMessageUpdated: data.dateQueued, messages: messages)
                }
            }
        }

        // 1. Remove messages sent from user
        let mailboxRemovingOutbound = mailbox?.filter {
            guard case .incomingMessage = $0 else { return false }
            return true
        }

        // 2. Find most recent message from remaining message (this will identify the active conversation)
        guard let mostRecentMessage = mailboxRemovingOutbound?.sorted(by: >).first else { return nil }

        if case let .incomingMessage(message: message) = mostRecentMessage {
            let allMessagesInConversation = messagesForRecipient(recipient: message.sender, mailbox: mailbox)
            return ActiveConversation(recipient: message.sender,
                                      lastMessageUpdated: message.dateReceived, messages: allMessagesInConversation)
        }
        return nil
    }

    /// Finds the inactive conversations in the inbox. If there are no messages in the mailbox, this returns nil. If there is 1 message in the mailbox, this returns nil - since 1 message would be considered the active conversation.
    static func findInactiveMessages(in mailbox: [Message]?) -> [InactiveConversation]? {
        // 1. Remove all outbound messages
        let mailboxRemovingOutbound = mailbox?.filter {
            guard case .incomingMessage = $0 else { return false }
            return true
        }

        // 2. Remove messages from the active message recipient
        guard case let .incomingMessage(activeMessage) = mailboxRemovingOutbound?.sorted(by: >).first else { return nil }

        let inactiveMailbox = mailboxRemovingOutbound?.filter {
            if case let .incomingMessage(message: message) = $0,
               message.sender == activeMessage.sender
            {
                return false
            }
            return true
        }
        guard let inactiveMailbox, inactiveMailbox.count > 0 else { return nil }

        // 3. Find the remaining recipients
        let recipients: [JournalistKeyData] = inactiveMailbox.compactMap {
            guard case let .incomingMessage(message: message) = $0 else { return nil }
            return message.sender
        }

        // 4. Return an array of inactive threads, in no particular order
        return recipients.map {
            let allMessagesInConversation = messagesForRecipient(recipient: $0, mailbox: mailbox)
            return InactiveConversation(recipient: $0, messages: allMessagesInConversation)
        }
    }

    static func messagesForRecipient(recipient: JournalistKeyData, mailbox: [Message]?) -> [Message] {
        return mailbox?.filter {
            switch $0 {
            case let .outboundMessage(message: outbound):
                return outbound.recipient == recipient

            case let .incomingMessage(message: incoming):
                return incoming.sender == recipient
            }
        } ?? []
    }

    ///
    /// This deletes all messages and current session by:
    ///  1. removing all messages from the inbox,
    ///  2. locking the current session to remove it from memory
    ///  3. overwrites the encrypted storage on disk with a new session with random passphrase
    ///  4. empties the private sending queue, so any pending messages are also removed, this is to allow users
    ///     to change their mind after sending a message.
    ///
    public func deleteAllMessagesAndCurrentSession() async throws {
        let publicDataRepository = PublicDataRepository.shared
        if case let .unlockedSecretData(unlockedData: unlockedSecretData) = secretDataRepository.secretData {
            unlockedSecretData.messageMailbox = []
            try await secretDataRepository.lock(data: unlockedSecretData, withSecureEnclave: SecureEnclave.isAvailable)
            try await EncryptedStorage.createInitialStorageWithRandomPassphrase(withSecureEnclave: SecureEnclave.isAvailable)

            if let coverMesage = try? CoverMessage.getCoverMessage() {
                try await PrivateSendingQueueRepository.shared.wipeQueue(coverMessage: coverMesage)
            }
        }
    }
}
