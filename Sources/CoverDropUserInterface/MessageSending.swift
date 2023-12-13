import CoverDropCore
import Foundation

/// A protocol which describes the functionality for sending messages.
protocol MessageSending {
    /// Sends the given message to a specified recipient.
    /// - Parameters:
    ///   - message: The message body.
    ///   - recipient: The given recipient.
    ///   - covernodeMessagePublicKey: A reqiured CoverNodeMessagingPublicKey
    ///   - secretDataRepository: A required instance of the SecretDataRepository
    /// - Returns: An optional error message used for the purposes of debugging
    func sendMessage(_ message: String,
                     to recipient: JournalistData,
                     verifiedPublicKeys: VerifiedPublicKeys,
                     secretDataRepository: SecretDataRepository, dateSent: Date) async throws
}

extension MessageSending {
    @MainActor
    func sendMessage(_ message: String,
                     to recipient: JournalistData,
                     verifiedPublicKeys: VerifiedPublicKeys,
                     secretDataRepository: SecretDataRepository, dateSent: Date) async throws {
        // add the current message to the private sending queue and
        // secret Data  Repository
        switch secretDataRepository.secretData {
        case let .unlockedSecretData(unlockedData: unlockedSecretData):
            do {
                let outboundMessage = OutboundMessageData(recipient: recipient,
                                                                messageText: message,
                                                                dateSent: dateSent)
                let userKey = unlockedSecretData.userKey.publicKey

                let coverNodeMessage = try await outboundMessage.toCoverNodeMessage(covernodeMessagePublicKey: verifiedPublicKeys,
                                                                                    userPublicKey: userKey)

                let hint = try await PrivateSendingQueueRepository.shared.enqueue(secret: unlockedSecretData.privateSendingQueueSecret,
                                                                                  message: coverNodeMessage)
                outboundMessage.hint = hint

                let newMessage: Message = .outboundMessage(message: outboundMessage)

                unlockedSecretData.addMessage(message: newMessage)

            } catch {
                throw "Failed to enqueue message"
            }
        case _:
            throw "Should not be in locked state on this page"
        }
    }
}
