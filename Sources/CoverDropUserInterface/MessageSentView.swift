import CoverDropCore
import SVGView
import SwiftUI

struct MessageSentView: View {
    @ObservedObject var navigation = Navigation.shared

    var body: some View {
        NavigationView {
            HeaderView(type: .messageSent, dismissAction: {
                Task {
                    navigation.destination = .home
                    if case let .unlockedSecretData(unlockedData: unlockedData) = SecretDataRepository.shared.secretData {
                        try await SecretDataRepository.shared.lock(unlockedData: unlockedData)
                    }
                }
            }) {
                VStack(alignment: .center) {
                    if let image = Bundle.module.url(forResource: "tickCircleIcon", withExtension: "svg") {
                        SVGView(contentsOf: image)
                            .frame(width: 40, height: 40)
                            .padding([.trailing], Padding.large)
                            .padding([.top], Padding.medium)
                            .foregroundColor(Color.MessageSentView.tickIconColor)
                    }
                    Text("Your message has been sent.").textStyle(GuardianHeaderTextStyle())
                    Text("Thank you. We hope to be in touch soon.").textStyle(BodyStyle())
                }
                .padding([.top], Padding.large)

                customDivider().padding([.trailing, .leading, .top], Padding.large)

                VStack(alignment: .leading) {
                    Text("What to expect next?").textStyle(GuardianHeadlineSmallTextStyle())
                    Text("Your message is now in our queue and will be received by our team soon.").textStyle(BodyStyle())
                    Text("Use your passphrase to check your secure mailbox for a response. We recommend that you wait for your message to be received before sending another one. Messages will stay in your inbox for 14 days.").textStyle(BodyStyle())

                    Spacer()

                    Button("Go to your inbox") {
                        navigation.destination = .inbox
                    }.buttonStyle(PrimaryButtonStyle(isDisabled: false))
                }.padding(Padding.large)
            }.foregroundColor(Color.MessageSentView.foregroundColor)
        }
    }
}
