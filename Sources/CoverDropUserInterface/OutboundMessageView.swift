import CoverDropCore
import CryptoKit
import Foundation
import SVGView
import SwiftUI

@MainActor
struct OutboundMessageView: View {
    @ObservedObject var outboundMessage: OutboundMessageData
    var id: Int
    let messageData: MessageData

    public init(outboundMessage: OutboundMessageData, id: Int) {
        self.outboundMessage = outboundMessage
        self.id = id
        messageData = ConversationViewModel.getOutboundMessageData(message: outboundMessage)
    }

    var body: some View {
        HStack(alignment: .bottom) {
            // Add a spacer so that messages send from this device appear on the left
            if messageData.isCurrentUser {
                Spacer().frame(minWidth: 30, maxWidth: 40)
            }
            VStack {
                if messageData.isCurrentUser {
                    HStack {
                        Spacer()
                        Text("You").bold()
                    }
                }
                VStack(alignment: .leading) {
                    Text(messageData.messageText).textStyle(BodyStyle())
                        .padding([.top, .leading, .trailing], Padding.medium)
                    customDivider()
                    HStack(alignment: .top) {
                        messageSentStatus(expiringStatus: messageData.status)

                        Spacer()
                        Text("\(messageData.dateSent, formatter: ConversationViewModel.messageDateFormat)")
                            .textStyle(MessageMetadata())
                            .padding([.trailing], Padding.medium)
                    }

                }.background(messageData.isCurrentUser ? Color.JournalistNewMessageView.messageViewCurrentUserColor : Color.JournalistNewMessageView.messageViewUnselectedUserColor)
                .cornerRadius(10)
                .padding([.bottom], Padding.medium)
            }
            .id(id)
            // And if we are not the current user put a spacer at the end!
            if !messageData.isCurrentUser {
                Spacer()
            }
        }
    }

    private func messageSentStatus(expiringStatus: MessageStatus) -> some View {
        HStack {
            if case let .expiring(expiryDate) = expiringStatus {
                Text("\(Image(systemName: "info.circle.fill")) Expiring in \(expiryDate)").textStyle(ExpiringMessageMetadata())
                    .padding([.leading], Padding.medium)
                    .accessibilityIdentifier("Expiring in")
            } else if outboundMessage.isPending {
                Text("\(Image(systemName: "clock.fill")) Pending").textStyle(PendingMessageMetadata())
                    .padding([.leading], Padding.medium)
                    .accessibilityIdentifier("Pending")
            } else {
                Text("\(Image(systemName: "checkmark.circle.fill")) Sent").textStyle(SentMessageMetadata())
                    .padding([.leading], Padding.medium)
                    .accessibilityIdentifier("Sent")
            }
        }
    }
}

struct OutboundMessageView_Previews: PreviewProvider {
    // swiftlint:disable force_try
    @MainActor struct Container: View {
        let privateSendingQueueRepo = initSendingQueue()
        @State var nonExpiredMessage = OutboundMessageData(recipient: PublicKeysHelper.shared.testDefaultJournalist!, messageText: "hey", dateSent: Date(timeIntervalSinceNow: TimeInterval(1 - (60 * 60 * 24 * 2))), hint: HintHmac(hint: PrivateSendingQueueHmac.hmac(secretKey: try! PrivateSendingQueueSecret.fromSecureRandom().bytes, message: "hey".asBytes())))

        @MainActor var body: some View {
            OutboundMessageView(outboundMessage: nonExpiredMessage, id: 1)
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
