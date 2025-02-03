import CoverDropCore
import Foundation

enum MessageSendingError: Error {
    case failedToEncryptMessage
    case secretDataNotUnlocked
}

enum MessageSending {
    @MainActor
    static func sendMessage(
        _ message: String,
        to recipient: JournalistData,
        lib: CoverDropLibrary,
        dateSent: Date
    ) async throws {
        // add the current message to the private sending queue and
        // secret Data  Repository

        guard case let .unlockedSecretData(unlockedSecretData) = lib.secretDataRepository.getSecretData() else {
            throw MessageSendingError.secretDataNotUnlocked
        }

        let userKey = unlockedSecretData.userKey.publicKey

        let encryptedMessage = try await UserToCoverNodeMessageData.createMessage(
            message: message,
            messageRecipient: recipient,
            publicDataRepository: lib.publicDataRepository,
            userPublicKey: userKey
        )

        let hint = try await PrivateSendingQueueRepository.shared.enqueue(
            secret: unlockedSecretData.privateSendingQueueSecret,
            message: encryptedMessage
        )

        let outboundMessage = OutboundMessageData(
            recipient: recipient,
            messageText: message,
            dateQueued: dateSent,
            hint: hint
        )

        let newMessage: Message = .outboundMessage(message: outboundMessage)

        try await lib.secretDataRepository.addMessage(message: newMessage)
    }
}
