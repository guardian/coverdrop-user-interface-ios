import SVGView
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var viewModel = OnboardingViewModel()

    var body: some View {
        HeaderView(type: .onboarding, dismissAction: {
            navigation.destination = .home
        }) {
            VStack(alignment: .leading, spacing: 0) {
                TabView(selection: $viewModel.currentStep) {
                    ForEach(OnboardingSteps.allCases) { step in
                        onboardingStep(step: step)
                    }
                }
                .tabViewStyle(.page)
            }
            .padding([.top, .leading, .trailing, .bottom], Padding.large)
            .foregroundColor(Color.white)
            Spacer()

            Button(viewModel.currentStep.buttonText) {
                if viewModel.isFinalStep() {
                    navigation.destination = .newPassphrase
                } else {
                    advanceToNextTab()
                }
            }
            .buttonStyle(PrimaryButtonStyle(isDisabled: false))
            .padding([.bottom, .leading, .trailing], Padding.large)
        }
        .navigationBarHidden(true)
    }

    func advanceToNextTab() {
        withAnimation {
            viewModel.advanceToNextTab()
        }
    }

    func onboardingStep(step: OnboardingSteps) -> some View {
        GeometryReader { metric in
            VStack(alignment: .center, spacing: 0) {
                Group {
                    step.image
                        .frame(width: 200, height: 200)
                        .padding([.bottom], Padding.large)
                    // the .frame sets the height as a percentage of the parent.
                    // Totally a magic number that works with and without the beta banner present
                }.frame(height: metric.size.height * 0.58)

                Text("How this works")
                    .textStyle(TitleStyle())

                Text(step.rawValue)
                    .textStyle(GuardianHeaderTextStyle())
                    .foregroundColor(Color.OnboardingView.textForegroundColor)
                    .padding(.bottom, Padding.medium)
                Text(step.description)
                    .textStyle(BodyStyle())
                    .padding(.top, Padding.small)
                    .padding([.leading, .trailing], Padding.medium)
                Spacer()

            }.foregroundColor(Color.white)
        }
    }
}

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingSteps = .sendMessage

    func advanceToNextTab() {
        switch currentStep {
        case .sendMessage:
            currentStep = .checkResponse
        case .checkResponse:
            currentStep = .getPassphrase
        case .getPassphrase:
            break
        }
    }

    func isFinalStep() -> Bool {
        currentStep == .getPassphrase
    }
}

enum OnboardingSteps: String, CustomStringConvertible, CaseIterable, Identifiable {
    var id: Self { self }

    case sendMessage = "Send a message"
    case checkResponse = "Check back for a response"
    case getPassphrase = "Memorise your passphrase"

    var description: String {
        switch self {
        case .sendMessage:
            return """
            Your message will be sent anonymously and securely to a journalist or a team. \
            It will be encrypted and indistinguishable from normal network traffic.
            """
        case .checkResponse:
            return """
            Our journalists monitor secure messages regularly. \
            If they wish to take your story further they will respond here. \
            To stay in touch you will need to return to your secure inbox using your passphrase.
            """
        case .getPassphrase:
            return """
            You will been shown a unique passphrase which you will use to unlock your secure inbox. \
            Please make sure you memorise it so you can return to your secure inbox later.
            """
        }
    }

    var image: SVGView? {
        var imageUrl: String

        switch self {
        case .sendMessage:
            imageUrl = "sendAMessageIcon"
        case .checkResponse:
            imageUrl = "checkBackForResponseIcon"
        case .getPassphrase:
            imageUrl = "memorisePassphraseIcon"
        }
        if let svg = Bundle.module.url(forResource: imageUrl, withExtension: "svg") {
            return SVGView(contentsOf: svg)
        } else {
            return nil
        }
    }

    var buttonText: String {
        switch self {
        case .sendMessage:
            return "Continue"
        case .checkResponse:
            return "Continue"
        case .getPassphrase:
            return "Set up my passphrase"
        }
    }
}

#Preview {
    OnboardingView()
}
