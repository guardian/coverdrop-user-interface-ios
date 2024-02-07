import CoverDropCore
import Foundation

enum MessageSendingError: Error {
    case failedToEncryptMessage
}

enum MessageSending {
    @MainActor
    static func sendMessage(_ message: String,
                            to recipient: JournalistData,
                            verifiedPublicKeys: VerifiedPublicKeys,
                            unlockedSecretDataRepository: UnlockedSecretDataService,
                            dateSent: Date) async throws {
        // add the current message to the private sending queue and
        // secret Data  Repository

        let userKey = unlockedSecretDataRepository.unlockedData.userKey.publicKey

        let encryptedMessage = try await UserToCoverNodeMessageData.createMessage(message: message, messageRecipient: recipient, covernodeMessagePublicKey: verifiedPublicKeys, userPublicKey: userKey)

        let hint = try await PrivateSendingQueueRepository.shared.enqueue(
            secret: unlockedSecretDataRepository.unlockedData.privateSendingQueueSecret,
            message: encryptedMessage
        )

        let outboundMessage = OutboundMessageData(
            messageRecipient: recipient,
            messageText: message,
            dateSent: dateSent,
            hint: hint
        )

        let newMessage: Message = .outboundMessage(message: outboundMessage)

        try await unlockedSecretDataRepository.addMessage(message: newMessage)
    }
}
