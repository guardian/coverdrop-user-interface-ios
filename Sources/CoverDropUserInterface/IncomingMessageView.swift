import CoverDropCore
import CryptoKit
import Foundation
import SVGView
import SwiftUI

@MainActor
struct IncomingMessageView: View {
    var message: IncomingMessageData
    var id: Int
    let messageData: MessageData

    public init(message: IncomingMessageData, id: Int) {
        self.message = message
        self.id = id
        messageData = ConversationViewModel.getIncomingMessageData(message: message)
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
                        if case let .expiring(expiryDate) = messageData.status {
                            Text("\(Image(systemName: "info.circle.fill")) Expiring in \(expiryDate)").textStyle(ExpiringMessageMetadata())
                                .padding([.leading], Padding.medium)
                                .accessibilityIdentifier("Expiring in")
                        }
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
}

struct MessageView_Previews: PreviewProvider {

    @MainActor struct Container: View {
        let privateSendingQueueRepo: () = PreviewHelper.initSendingQueue()
        @State var nonExpiredMessage = IncomingMessageData(sender: PublicKeysHelper.shared.testDefaultJournalist!, messageText: "hey", dateReceived: Date(timeIntervalSinceNow: TimeInterval(1 - (60 * 60 * 24 * 2))))

        @MainActor var body: some View {
            IncomingMessageView(message: nonExpiredMessage, id: 1)
        }
    }

    static var previews: some View {
        Container()
    }
}
