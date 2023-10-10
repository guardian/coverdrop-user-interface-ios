import SVGView
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var navigation = Navigation.shared
    @State var isNewPassphraseModalOpen = false

    var body: some View {
        HeaderView(type: .onboarding, dismissAction: {
            navigation.destination = .home
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Text("How this works")
                    .textStyle(TitleStyle())
                    .padding(.leading, 1) // alignment workaround for tabview scrollview inset
                TabView {
                    ForEach(OnboardingViewModel.OnboardingSteps.allCases) { step in
                        onboardingStep(step: step)
                    }
                }
                .tabViewStyle(.page)
            }
            .padding([.top, .leading, .trailing], Padding.large)
            .foregroundColor(Color.white)

            Button("Continue") {
                navigation.destination = .newPassphrase
            }
            .buttonStyle(PrimaryButtonStyle(isDisabled: false))
            .padding([.bottom, .leading, .trailing], Padding.large)
        }
        .navigationBarHidden(true)
    }

    func onboardingStep(step: OnboardingViewModel.OnboardingSteps) -> some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(step.rawValue)
                    .textStyle(GuardianHeaderTextStyle())
                    .foregroundColor(Color.OnboardingView.textForegroundColor)
                Text(step.description)
                    .textStyle(BodyStyle())
                    .padding(.top, 12)
            }

            VStack(alignment: .center) {
                step.image
                    .frame(width: 200, height: 200)
                    .padding([.top], Padding.xLarge * 4)

                Spacer()
            }
            Spacer()
        }.foregroundColor(Color.white)
    }
}

enum OnboardingViewModel {
    enum OnboardingSteps: String, CustomStringConvertible, CaseIterable, Identifiable {
        var id: Self { self }

        case getPassphrase = "Memorise passphrase"
        case sendMessage = "Send a message"
        case checkResponse = "Check back for a response"

        var description: String {
            switch self {
            case .getPassphrase:
                return "You’ll receive a passphrase which will be used to unlock your secure inbox. When you receive this, make sure you memorise it so you can continue your conversation later."
            case .sendMessage:
                return "You’ll send a new message to a journalist or a team of journalists. Our system will queue your message with other ‘cover’ messages so it can be sent anonymously and securely."
            case .checkResponse:
                return "You’ll need to come back regularly to your secure inbox using your passphrase to check the status of your messages and continue your conversation."
            }
        }

        var image: SVGView? {
            var imageUrl: String

            switch self {
            case .getPassphrase:
                imageUrl = "memorisePassphraseIcon"
            case .sendMessage:
                imageUrl = "sendAMessageIcon"
            case .checkResponse:
                imageUrl = "checkBackForResponseIcon"
            }
            if let svg = Bundle.module.url(forResource: imageUrl, withExtension: "svg") {
                return SVGView(contentsOf: svg)
            } else {
                return nil
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper(OnboardingView())
    }
}
