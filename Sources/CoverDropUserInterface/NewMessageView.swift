import CoverDropCore
import SwiftUI

struct NewMessageView: View {
    @ObservedObject var navigation = Navigation.shared
    @State var isMessageViewLinkActive = false
    @State var isSelectRecipientViewOpen = false
    @State private var showingDismissalAlert = false
    var isInboxEmpty: Bool

    // In practice, this view model's optionals should never be nil if accessed when state == .ready. Force unwrapping will allow us to fail fast in the case of developer error.
    @StateObject var viewModel: ConversationViewModel

    init(viewModel: ConversationViewModel, inboxIsEmpty: Bool = false) {
        UITextView.appearance().backgroundColor = .clear
        self.isInboxEmpty = inboxIsEmpty

        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        switch viewModel.state {
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
            ScrollView {
                VStack(alignment: .leading) {
                    if isInboxEmpty {
                        InformationView(viewType: .info, title: "Looks like you haven’t sent your message yet", message: "Enter your message to start a conversation.")
                    }
                    Text("What do you want to share with us?")
                        .textStyle(TitleStyle())
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Who would you like to contact?")
                            .textStyle(FormLabelTextStyle())
                        Text("Change the recipient if you know which desk or journalist you’d like to contact.")
                            .textStyle(BodyStyle())
                    }

                    ZStack(alignment: .trailing) {
                        if let messageRecipient = viewModel.messageRecipient {
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
                        if let recipients = viewModel.recipients {
                            Button(action: {
                                isSelectRecipientViewOpen = true
                            }, label: {
                                HStack(alignment: .center) {
                                    Image(systemName: "pencil").resizable().frame(width: 12, height: 12)
                                    Text("Edit").textStyle(InlineTextButtonStyle())
                                }
                            }).sheet(isPresented: $isSelectRecipientViewOpen) {
                                SelectRecipientView(isSelectRecipientViewOpen: $isSelectRecipientViewOpen,
                                                    selectedRecipient: $viewModel.messageRecipient,
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
                                if case let .unlockedSecretData(unlockedData: unlockedData) = SecretDataRepository.shared.secretData {
                                    navigation.destination = .inbox
                                    try await SecretDataRepository.shared.lock(unlockedData: unlockedData)
                                }
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                       }, message: {
                        Text("You will be leaving your secure inbox and your message will not be sent.\n Do you want to continue?")
                       })
            }
        }
    }

    @ViewBuilder
    func messageSend() -> some View {
        Spacer()
        Rectangle().fill(Color.NewMessageView.messageToLongErrorColor)
            .frame(height: 2)
            .opacity(viewModel.messageIsTooLong ? 1 : 0)
        ZStack {
            // Send button
            Button("Send message") {
                Task {
                    do {
                        try await viewModel.sendMessage()
                        viewModel.clearMessage()
                        isMessageViewLinkActive = true
                    } catch {
                        // We drop errors sliently to avoid giving away any user interaction in logs
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(isDisabled: viewModel.sendButtonDisabled))
            .disabled(viewModel.sendButtonDisabled)
            .opacity(viewModel.messageIsTooLong ? 0 : 1)
            // Show an error on top, in case the message is too long
            HStack {
                VStack(alignment: .leading) {
                    Label("Message limit reached", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.NewMessageView.messageToLongErrorColor)
                        .font(.textSansBold,
                              size: FontSize.bodyText,
                              lineHeight: 23)
                    Text("Please shorten your message")
                        .textStyle(BodyStyle())
                        .padding(.leading, 28)
                }
                .opacity(viewModel.messageIsTooLong ? 1 : 0)
            }
        }
    }

    @ViewBuilder
    func messageCompose() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Topic")
                .textStyle(FormLabelTextStyle())
            Text("Describe your message in a few keywords.")
                .textStyle(FormLabelSubtitleTextStyle())
        }
        TextEditor(text: $viewModel.topic)
            .style(ComposeMessageTextStyle())
            .accessibilityIdentifier("Your message topic")
            .frame(height: 44)
        Spacer()
        VStack(alignment: .leading, spacing: 0) {
            Text("What's your message?")
                .textStyle(FormLabelTextStyle())
            Text("Please include a bit about yourself.")
                .textStyle(FormLabelSubtitleTextStyle())
        }
        TextEditor(text: $viewModel.message)
            .style(ComposeMessageTextStyle())
            .accessibilityIdentifier("Compose your message")
            .frame(height: 140)

        Spacer()
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper(NewMessageView(viewModel: viewModel()))
    }

    private static func viewModel() -> ConversationViewModel {
        return ConversationViewModel(verifiedPublicKeys: PublicKeysHelper.shared.testKeys)
    }

    private static func viewModelWithALongMessage() -> ConversationViewModel {
        let viewModel = viewModel()
        let shortMessage = "This will be an incredibly long message."
        viewModel.message = shortMessage

        for _ in 1 ... 2000 {
            viewModel.message.append(contentsOf: shortMessage)
        }

        return viewModel
    }
}
