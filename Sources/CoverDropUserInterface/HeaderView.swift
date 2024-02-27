import Foundation
import SVGView
import SwiftUI
struct HeaderView<Content: View>: View {
    let content: Content
    let type: Destination
    @State private var showingScreenshotDetectedAlert = false

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
                    Button(action: {
                        // This will navigate a view hierarchy back to the previous screen,
                        // or close a modal window if its open.
                        guard let dismissAction else { presentation.wrappedValue.dismiss(); return }
                        dismissAction()
                    }) {
                        Image(systemName: "arrow.backward")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .padding(Padding.large)
                            .foregroundColor(Color.HeaderView.arrowColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(backButtonText())

                    Spacer() // This pushed the button to the left corner

                    if let image = Bundle.module.url(forResource: "logo", withExtension: "svg") {
                        SVGView(contentsOf: image)
                            .frame(width: 200, height: 50)
                            .padding([.trailing], Padding.large)
                            .padding([.top], Padding.small)
                    }
                }
                .background(Color.HeaderView.backgroundColor)
                .padding(0)

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
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            showingScreenshotDetectedAlert = true
        }
    }

    func backButtonText() -> String {
        switch type {
        case .login, .viewConversation, .onboarding, .inbox:
            return "Close \(type)"
        case .home, .privacy, .about, .messageSent, .newConversation, .deskDetail, .selectRecipient, .newPassphrase:
            return "Go Back"
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
