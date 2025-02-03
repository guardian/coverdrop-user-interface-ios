import CoverDropCore
import SVGView
import SwiftUI

struct MessageSentView: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var lib: CoverDropLibrary
    @ObservedObject var conversationViewModel: ConversationViewModel

    var body: some View {
        NavigationView {
            HeaderView(type: .messageSent, dismissAction: {
                Task {
                    navigation.destination = .home
                    await conversationViewModel.clearModelDataAndLock()
                }
            }) {
                VStack(alignment: .center) {
                    Text("Your message will be received by a journalist soon.").textStyle(GuardianHeaderTextStyle())
                    Text("Go about your normal day.").textStyle(BodyStyle())
                }
                .padding([.top], Padding.large)

                customDivider().padding([.trailing, .leading, .top], Padding.large)

                VStack(alignment: .leading) {
                    Text("What to expect next?").textStyle(GuardianHeadlineSmallTextStyle())
                    Text("Your message is now in our queue and will be received by our team soon.")
                        .textStyle(BodyStyle())
                    Text("""
                    Your message is being disguised. It will be received by a Guardian journalist within a few hours.
                    """)
                    .textStyle(BodyStyle())
                    Text("Use the passphrase you memorised to access this conversation again.")
                        .textStyle(BodyStyle())
                    Text("""
                    Journalists aim to respond in a reasonable time frame. \
                    However in busy times replies can take several days. For security reasons you will not \
                    receive a notification. You have to come back here and check.
                    """)
                    .textStyle(BodyStyle())

                    InformationView(viewType: .action, title: "What to expect as a reply", message: "Read more")
                        .padding(.top, Padding.medium)

                    Spacer()

                    Button("Review conversation") {
                        navigation.destination = .inbox
                    }.buttonStyle(PrimaryButtonStyle(isDisabled: false))
                    Button("Log out from Secure Messaging") {
                        Task {
                            await conversationViewModel.clearModelDataAndLock()
                            navigation.destination = .home
                        }
                    }.buttonStyle(SecondaryButtonStyle(isDisabled: false))
                }.padding(Padding.large)
            }.foregroundColor(Color.MessageSentView.foregroundColor)
        }
    }
}
