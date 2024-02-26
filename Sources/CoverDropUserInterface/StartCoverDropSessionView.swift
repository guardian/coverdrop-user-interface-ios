import CoverDropCore
import Foundation
import SVGView
import SwiftUI

struct StartCoverDropSessionView: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject private var viewModel = StartCoverDropSessionViewModel()
    @ObservedObject private var publicDataRepository = PublicDataRepository.shared

    /// Controls whether the alert is shown before starting a new conversation
    @State private var showingNewMessageAlert = false

    init() {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }

    var body: some View {
        NavigationView {
            HeaderView(type: .home) {
                VStack(alignment: .leading) {
                    titleText.textStyle(LargeTitleStyle()).font(Font.headline.leading(.loose))

                    Text("Our Secure Messaging service was developed by the Guardian to allow you to share stories with us securely and privately using strong encryption. It is designed to prevent others from even knowing you are in communication with us.").textStyle(BodyStyle())

                    Spacer()

                    if let coverDropServiceStatus = publicDataRepository.coverDropServiceStatus,
                       coverDropServiceStatus.isAvailable == false {
                        VStack {
                            Text("The Secure Messaging feature is currently not available. Please try again later. Below we show technical information that might be helpful.")
                            Text(coverDropServiceStatus.description).textStyle(MonoSpacedStyle())
                        }

                    } else {
                        Button("Get started") {
                            showingNewMessageAlert = true
                        }
                        .disabled(!viewModel.keysAvailable)
                        .buttonStyle(PrimaryButtonStyle(isDisabled: !viewModel.keysAvailable))
                        .alert("Set up your secure inbox", isPresented: $showingNewMessageAlert, actions: {
                            Button("Yes, start conversation") {
                                navigation.destination = .onboarding
                                viewModel.viewHidden()
                            }
                            Button("No", role: .cancel) {}
                        }, message: {
                            Text("Starting a new conversation will remove any prior messages from your inbox, if they existed. Do you want to continue?")
                        })

                        Button("Check your inbox") {
                            navigation.destination = .login
                            viewModel.viewHidden()
                        }.buttonStyle(SecondaryButtonStyle(isDisabled: false))
                    }

                }.padding(Padding.large)
                    .foregroundColor(Color.StartCoverDropSessionView.foregroundColor)

                if let coverDropServiceStatus = publicDataRepository.coverDropServiceStatus,
                   coverDropServiceStatus.isAvailable {
                    customDivider()
                    HStack(alignment: .center) {
                        Button("About Secure Messaging") {
                            navigation.destination = .about
                            viewModel.viewHidden()
                        }.buttonStyle(FooterButtonStyle())
                        Button("Privacy policy") {
                            navigation.destination = .privacy
                            viewModel.viewHidden()
                        }.buttonStyle(FooterButtonStyle())
                    }.padding([.leading], Padding.small)
                }
            }
        }
    }

    var titleText: Text {
        Text("Send us a message ").foregroundColor(Color.StartCoverDropSessionView.firstLineTextForegroundColor)
            + Text("securely").foregroundColor(Color.StartCoverDropSessionView.secondLineTextForegroundColor)
            + Text(" and ").foregroundColor(Color.StartCoverDropSessionView.firstLineTextForegroundColor)
            + Text("privately").foregroundColor(Color.StartCoverDropSessionView.secondLineTextForegroundColor)
    }
}

struct StartCoverDropSessionView_Previews: PreviewProvider {
    @MainActor struct Container: View {
        let setup: () = setupView()

        @MainActor var body: some View {
            let _: () = setAvailabe()
            PreviewWrapper(StartCoverDropSessionView())
            let _: () = setUnavailabe()
            PreviewWrapper(StartCoverDropSessionView())
        }
    }

    public static func setAvailabe() {
        PublicDataRepository.shared.coverDropServiceStatus = StatusData(status: .available, description: "Service is available", timestamp: RFC3339DateTimeString(date: Date()), isAvailable: true)
    }

    public static func setUnavailabe() {
        PublicDataRepository.shared.coverDropServiceStatus = StatusData(status: .noInformation, description: "Service is unavailable", timestamp: RFC3339DateTimeString(date: Date()), isAvailable: false)
    }

    public static func setupView() {
        PublicDataRepository.setup(StaticConfig.devConfig)
        PublicDataRepository.shared.areKeysAvailable = true
        CoverDropServices.shared.isReady = true
        PublicDataRepository.shared.coverDropServiceStatus = StatusData(status: .available, description: "", timestamp: RFC3339DateTimeString(date: Date()), isAvailable: true)
    }

    static var previews: some View {
        Container()
    }
}
