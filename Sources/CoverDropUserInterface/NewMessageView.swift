import CoverDropCore
import SwiftUI

struct NewMessageView: View {
    @Binding var navPath: NavigationPath
    @State var isMessageViewLinkActive = false
    @State var isSelectRecipientViewOpen = false
    @State private var showingDismissalAlert = false
    var isInboxEmpty: Bool

    // In practice, this view model's optionals should never be nil if accessed when state == .ready. Force unwrapping
    // will allow us to fail fast in the case of developer error.
    @ObservedObject var conversationViewModel: ConversationViewModel

    init(conversationViewModel: ConversationViewModel, navPath: Binding<NavigationPath>, inboxIsEmpty: Bool = false) {
        _navPath = navPath

        UITextView.appearance().backgroundColor = .clear
        isInboxEmpty = inboxIsEmpty
        self.conversationViewModel = conversationViewModel
    }

    var body: some View {
        switch conversationViewModel.state {
        case .initial, .loading, .sending:
            ProgressView()
        case .ready:
            newMessage()
        case let .error(error):
            Text("Error: \(error)")
        }
    }

    private func newMessage() -> some View {
        HeaderView(type: .home,
                   dismissAction: {
                       showingDismissalAlert = true
                   }) {
            CraftMessageBannerView(action: {
                navPath.append(Destination.help(contentVariant: .craftMessage))
            })
            ScrollView {
                VStack(alignment: .leading) {
                    if isInboxEmpty {
                        InformationView(
                            viewType: .info,
                            title: "Looks like you haven’t sent your message yet",
                            message: "Enter your message to start a conversation."
                        )
                    }
                    Text("What do you want to share with us?")
                        .textStyle(TitleStyle())
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Who would you like to contact?")
                            .textStyle(FormLabelTextStyle())
                        Text("Change the recipient if you know which team or journalist you would like to contact.")
                            .textStyle(BodyStyle())
                    }

                    ZStack(alignment: .trailing) {
                        if let messageRecipient = conversationViewModel.messageRecipient {
                            Text("\(messageRecipient.displayName)")
                                .textStyle(SelectRecipientTextStyle())
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                                .accessibilityIdentifier("Selected Recipient is \(messageRecipient.displayName)")
                        } else {
                            Text("No recipient selected")
                                .textStyle(SelectRecipientTextStyle())
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                                .accessibilityIdentifier("Selected Recipient")
                        }
                        if let recipients = conversationViewModel.recipients {
                            Button(action: {
                                isSelectRecipientViewOpen = true
                            }, label: {
                                HStack(alignment: .center) {
                                    Image(systemName: "pencil").resizable().frame(width: 12, height: 12)
                                    Text("Change recipient").textStyle(InlineButtonTextStyle())
                                }
                            }).sheet(isPresented: $isSelectRecipientViewOpen) {
                                SelectRecipientView(isSelectRecipientViewOpen: $isSelectRecipientViewOpen,
                                                    selectedRecipient: $conversationViewModel.messageRecipient,
                                                    recipients: recipients)
                            }
                            .accessibilityIdentifier("Select a Recipient")
                            .padding([.trailing], Padding.medium)
                        }
                    }
                    .padding([.bottom], Padding.xLarge)
                    Spacer()
                    messageCompose()
                    Spacer()
                    messageSend()
                }
                .padding(Padding.large)
                .foregroundColor(Color.NewMessageView.foregroundColor)
                .onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }.navigationBarHidden(true)
                .navigationBarTitle(Text(""))
                .alert("Leaving your inbox",
                       isPresented: $showingDismissalAlert,
                       actions: {
                           Button("Yes, I want to leave") {
                               Task {
                                   await conversationViewModel.clearModelDataAndLock()
                               }
                           }
                           Button("Cancel", role: .cancel) {}
                       }, message: {
                           Text(
                               """
                                You will be leaving your secure inbox and your message will not be sent.\n
                                Do you want to continue?
                               """
                           )
                       })
            }
        }
    }

    @ViewBuilder
    func messageSend() -> some View {
        Spacer()
        Rectangle().fill(Color.NewMessageView.messageToLongErrorColor)
            .frame(height: 2)
            .opacity(conversationViewModel.messageIsTooLong ? 1 : 0)
        ZStack {
            // Send button
            Button("Send message") {
                Task {
                    do {
                        try await conversationViewModel.sendMessage()
                        conversationViewModel.clearMessage()
                        isMessageViewLinkActive = true
                    } catch {
                        // We drop errors sliently to avoid giving away any user interaction in logs
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(isDisabled: conversationViewModel.sendButtonDisabled))
            .disabled(conversationViewModel.sendButtonDisabled)
        }
    }

    @ViewBuilder
    func messageCompose() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What's your message?")
                .textStyle(FormLabelTextStyle())
            Text("Please include a bit about yourself.")
                .textStyle(FormLabelSubtitleTextStyle())
        }
        VStack(alignment: .leading, spacing: 0) {
            MessageLengthProgressView(
                messageLengthProgressPercentage: conversationViewModel.messageLengthProgressPercentage
            )
            TextEditor(text: $conversationViewModel.message)
                .style(ComposeMessageTextStyle())
                .accessibilityIdentifier("Compose your message")
                .frame(height: 240)
        }

        Spacer()
    }
}

// struct NewMessageView_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewWrapper(NewMessageView(viewModel: viewModel()))
//        PreviewWrapper(NewMessageView(
//            viewModel: viewModelWithALongMessage()
//        ))
//    }
//
//    private static func viewModel() -> ConversationViewModel {
//        return ConversationViewModel(
//            verifiedPublicKeys: PublicKeysHelper.shared.testKeys,
//            config: StaticConfig.devConfig
//        )
//    }
//
//    private static func viewModelWithALongMessage() -> ConversationViewModel {
//        let viewModel = viewModel()
//        let shortMessage = """
//        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer dolor
//                nulla, ornare et tristique imperdiet, dictum sit amet velit. Curabitur pharetra erat sed
//                neque interdum, non mattis tortor auctor. Curabitur eu ipsum ac neque semper eleifend.
//                Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
//                Integer erat mi, ultrices nec arcu ut, sagittis sollicitudin est. In hac habitasse
//                platea dictumst. Sed in efficitur elit. Curabitur nec commodo elit. Aliquam tincidunt
//                rutrum nisl ut facilisis. Aenean ornare ut mauris eget lacinia. Mauris a felis quis orci
//                auctor varius sit amet eget est. Curabitur a urna sit amet diam sagittis aliquet eget eu
//                sapien. Curabitur a pharetra purus.
//                Nulla facilisi. Suspendisse potenti. Morbi mollis aliquet sapien sed faucibus. Donec
//                aliquam nibh nibh, ac faucibus felis aliquam at. Pellentesque egestas enim sem, eu
//                tempor urna posuere eget. Cras fermentum commodo neque ac gravida.
//        """
//        viewModel.message = shortMessage
//
//        viewModel.message.append(contentsOf: shortMessage)
//
//        return viewModel
//    }
// }
