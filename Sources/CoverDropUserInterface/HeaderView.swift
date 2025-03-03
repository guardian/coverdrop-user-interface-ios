import Foundation
import SVGView
import SwiftUI

struct HeaderView<Content: View>: View {
    let content: Content
    let type: Destination
    @State private var showingScreenshotDetectedAlert = false
    @State private var showingBetaBannerAlert = false
    @AppStorage("showBetaBanner") var showBetaBanner: Bool = true

    /// An optional closure to allow a view to implement its own dismissal logic. If `nil`, the parent view will be
    /// dismissed when the back button is pressed.
    let dismissAction: (() -> Void)?

    @Environment(\.presentationMode) var presentation: Binding<PresentationMode>

    init(type: Destination,
         dismissAction: (() -> Void)? = nil,
         @ViewBuilder _ content: () -> Content) {
        self.content = content()
        self.type = type
        self.dismissAction = dismissAction
    }

    var body: some View {
        ZStack {
            Color.HeaderView.fillColor
                .ignoresSafeArea(.all)
            VStack(spacing: 0) {
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

                if showBetaBanner {
                    BetaBannerView(
                        showBetaBannerAlert: $showingBetaBannerAlert
                    )
                }

                customDivider()

                content
            }.alert(
                """
                You took a screenshot.
                These screenshots can appear in your photo library, so this may be a security risk.
                """,
                isPresented: $showingScreenshotDetectedAlert
            ) {
                Button("OK", role: .cancel) {
                    showingScreenshotDetectedAlert = false
                }
            }
            .alert(
                "This is a test version of a new feature.",
                isPresented: $showingBetaBannerAlert
            ) {
                Button("Ok", role: .cancel) {}
                Button("Hide warning", role: .destructive) {
                    showBetaBanner = false
                }
            } message: {
                Text("""
                You can try it out but please do not yet use it to \
                tell us anything that is very important or sensitive.

                We cannot guarantee your message will be read.

                When the feature is ready for full use we will remove the 'Beta' warnings.

                You can temporarily hide the warning banner for this session.
                """)
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            showingScreenshotDetectedAlert = true
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
        })
    }
}
