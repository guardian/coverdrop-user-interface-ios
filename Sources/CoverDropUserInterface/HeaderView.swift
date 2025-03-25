import CoverDropCore
import Foundation
import SVGView
import SwiftUI

struct HeaderView<Content: View>: View {
    let content: Content
    let type: Destination
    @State private var showingScreenshotDetectedAlert = false
    @State private var showingBetaBannerAlert = false
    @Binding private var keyboardVisible: Bool

    /// An optional closure to allow a view to implement its own dismissal logic. If `nil`, the parent view will be
    /// dismissed when the back button is pressed.
    let dismissAction: (() -> Void)?

    @Environment(\.presentationMode) var presentation: Binding<PresentationMode>
    @Environment(CoverDropUserInterfaceConfiguration.self) var uiConfig

    init(
        type: Destination,
        dismissAction: (() -> Void)? = nil,
        keyboardVisible: Binding<Bool> = .constant(false),
        @ViewBuilder _ content: () -> Content
    ) {
        self.content = content()
        self.type = type
        self.dismissAction = dismissAction
        _keyboardVisible = keyboardVisible
    }

    var body: some View {
        ZStack {
            Color.HeaderView.fillColor
                .ignoresSafeArea(.all)
            VStack(spacing: 0) {
                if !keyboardVisible {
                    HStack(spacing: 0) {
                        if type != .inbox {
                            Button(action: {
                                // This will navigate a view hierarchy back to the previous screen,
                                // or close a modal window if its open.
                                guard let dismissAction else { presentation.wrappedValue.dismiss(); return }
                                dismissAction()
                            }) {
                                Image(systemName: backButtonImageName())
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .padding(Padding.large)
                                    .foregroundColor(Color.HeaderView.arrowColor)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(backButtonText())
                        }

                        Spacer() // This pushed the button to the left corner

                        if let image = Bundle.module.url(forResource: "logo", withExtension: "svg") {
                            SVGView(contentsOf: image)
                                .frame(width: 180, height: 45)
                                .padding([.trailing], Padding.large)
                                .padding([.vertical], Padding.medium)
                        }
                    }
                    .background(Color.HeaderView.backgroundColor)
                    .padding(0)
                    .transition(.move(edge: .top))

                    if uiConfig.showBetaBanner && type != .newPassphrase && type != .messageSent {
                        BetaBannerView(
                            showBetaBannerAlert: $showingBetaBannerAlert
                        )
                        .transition(.move(edge: .top))
                        .alert(
                            "Secure Messaging: public test",
                            isPresented: $showingBetaBannerAlert
                        ) {
                            Button("Ok", role: .cancel) {}
                            Button("Hide warning", role: .destructive) {
                                DispatchQueue.main.async {
                                    uiConfig.showBetaBanner = false
                                }
                            }
                        } message: {
                            Text("""
                            Feel free to try out this new way to contact Guardian reporters. \
                            However, during this test period we can't guarantee that all messages \
                            will be read. You may want to consider the alternatives described in \
                            theguardian.com/tips.

                            If you don't need to stay anonymous we'd welcome feedback at userhelp@theguardian.com.
                            """)
                        }
                    }

                    customDivider()
                }

                content
            }
        }
    }

    func backButtonText() -> String {
        switch type {
        case .login, .viewConversation, .onboarding, .inbox:
            return "Close \(type)"
        case .home, .about, .messageSent, .newConversation,
             .deskDetail, .selectRecipient, .newPassphrase, .help:
            return "Go Back"
        }
    }

    func backButtonImageName() -> String {
        switch type {
        case .login, .viewConversation, .onboarding, .inbox, .about, .messageSent, .newConversation,
             .deskDetail, .selectRecipient, .newPassphrase, .help:
            return "arrow.backward"
        case .home:
            return "xmark"
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper(HeaderView(type: .login) {
            EmptyView()
        }).environment(CoverDropUserInterfaceConfiguration(showAboutScreenDebugInformation: true, showBetaBanner: true))
    }
}
