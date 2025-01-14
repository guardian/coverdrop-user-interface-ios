import Foundation
import SVGView
import SwiftUI

struct AboutCoverDropView: View {
    @ObservedObject var navigation = Navigation.shared

    func navigateToHelp(contentVariant: HelpScreenContent) {
        navigation.destination = .help(contentVariant: contentVariant)
    }

    var body: some View {
        NavigationView {
            HeaderView(type: .about, dismissAction: {
                navigation.destination = .home
            }) {
                VStack(alignment: .leading) {
                    Text("About Secure Messaging").textStyle(LargeTitleStyle()).font(Font.headline.leading(.loose))

                    // TODO: Only placeholders for now, see: https://github.com/guardian/coverdrop/issues/2399
                    Button(action: { navigateToHelp(contentVariant: .howSecureMessagingWorks) }) {
                        Text("How Secure Messaging works")
                    }
                    Button(action: { navigateToHelp(contentVariant: .whyWeMadeSecureMessaging) }) {
                        Text("Why we made Secure Messaging")
                    }
                    Button(action: { navigateToHelp(contentVariant: .faq) }) {
                        Text("FAQs")
                    }
                    Button(action: { navigateToHelp(contentVariant: .privacyPolicy) }) {
                        Text("Privacy policy")
                    }
                    Button(action: { navigateToHelp(contentVariant: .craftMessage) }) {
                        Text("Craft your first message")
                    }
                    Button(action: { navigateToHelp(contentVariant: .keepingPassphraseSafe) }) {
                        Text("Keeping passphrases safe")
                    }
                    Button(action: { navigateToHelp(contentVariant: .replyExpectations) }) {
                        Text("What to expect as a reply")
                    }
                    Button(action: { navigateToHelp(contentVariant: .sourceProtection) }) {
                        Text("Source protection")
                    }

                }.padding(Padding.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Spacer()
            }
        }.foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
            .navigationBarHidden(true)
    }
}
