import CoverDropCore
import SVGView
import SwiftUI

struct MessageSentView: View {
    @ObservedObject var lib: CoverDropLibrary
    @ObservedObject var conversationViewModel: ConversationViewModel
    @Binding var navPath: NavigationPath

    var body: some View {
        HeaderView(type: .messageSent, dismissAction: {
            Task {
                await conversationViewModel.clearModelDataAndLock()
            }
            if !navPath.isEmpty {
                navPath.removeLast()
            }
        }) {
            VStack(alignment: .center) {
                Text("Your message will be received by a journalist soon.").textStyle(GuardianHeaderTextStyle())
            }
            .padding([.top], Padding.large)

            customDivider().padding([.trailing, .leading, .top], Padding.large)

            VStack(alignment: .leading) {
                ScrollView {
                    Text("What to happens next?").textStyle(GuardianHeadlineSmallTextStyle())
                    Text(
                        """
                        Your message is being disguised. \
                        It will be received by a Guardian journalist within a few hours. \
                        Use the passphrase you memorised to access this conversation again.

                        Journalists aim to respond in a reasonable time frame. \
                        However in busy times replies can take several days. For security reasons you will not \
                        receive a notification. You have to come back here and check.
                        """
                    )
                    .textStyle(BodyStyle())
                    .fixedSize(horizontal: false, vertical: true)

                    InformationView(
                        viewType: .action,
                        title: "What to expect as a reply", message: "Read more", action: {
                            navPath.append(Destination.help(contentVariant: .replyExpectations))
                        }
                    )
                    .padding(.top, Padding.medium)
                }
                Spacer()

                Button("Review conversation") {
                    navPath.append(Destination.inbox)
                }.buttonStyle(PrimaryButtonStyle(isDisabled: false))
                Button("Log out from Secure Messaging") {
                    Task {
                        await conversationViewModel.clearModelDataAndLock()
                        navPath.isEmpty ? () : navPath.removeLast()
                    }
                }.buttonStyle(SecondaryButtonStyle(isDisabled: false))
            }.padding(Padding.large)
        }.foregroundColor(Color.MessageSentView.foregroundColor)
    }
}

#Preview {
    @Previewable @State var loaded: Bool = false
    @Previewable @State var conversationViewModel: ConversationViewModel?
    @Previewable @State var library: CoverDropLibrary?

    Group {
        if loaded {
            MessageSentView(
                lib: library!,
                conversationViewModel: conversationViewModel!,
                navPath: .constant(NavigationPath())
            )
        } else {
            Group {
                LoadingView()
            }
        }
    }.onAppear {
        Task {
            let context = IntegrationTestScenarioContext(scenario: .minimal, config: StaticConfig.devConfig)
            let lib = try context.getLibraryWithVerifiedKeys()
            library = lib
            conversationViewModel = ConversationViewModel(lib: lib)
            loaded = true
        }
    }
    .previewFonts()
    .environment(CoverDropUserInterfaceConfiguration(showAboutScreenDebugInformation: true, showBetaBanner: true))
}
