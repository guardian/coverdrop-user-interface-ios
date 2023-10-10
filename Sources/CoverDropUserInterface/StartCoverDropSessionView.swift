import Foundation
import SVGView
import SwiftUI

struct StartCoverDropSessionView: View {
    @ObservedObject var navigation = Navigation.shared

    /// Controls whether the alert is shown before starting a new conversation
    @State private var showingNewMessageAlert = false

    @ObservedObject private var viewModel = StartCoverDropSessionViewModel()

    init() {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }

    var body: some View {
        NavigationView {
            HeaderView(type: .home) {
                VStack(alignment: .leading) {
                    titleText.textStyle(LargeTitleStyle()).font(Font.headline.leading(.loose))

                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras condimentum, massa id interdum luctus, lacus velit pulvinar enim, eu malesuada metus turpis eu quam. Nunc augue magna, sodales a scelerisque eget, interdum vitae leo. Aliquam nec elementum lacus, a accumsan purus.").textStyle(BodyStyle())

                    Spacer()

                    Button("Start a new conversation") {
                        showingNewMessageAlert = true
                    }
                    .disabled(!viewModel.keysAvailable)
                    .buttonStyle(PrimaryButtonStyle(isDisabled: !viewModel.keysAvailable))
                    .alert("Set up your secure inbox", isPresented: $showingNewMessageAlert, actions: {
                        Button("Yes, start conversation") {
                            navigation.destination = .onboarding
                            viewModel.viewHidden()
                        }
                        Button("Cancel", role: .cancel) {}
                    }, message: {
                        Text("This will remove any existing messages from your secure inbox. Do you want to continue?")
                    })

                    Button("Check your inbox") {
                        navigation.destination = .login
                        viewModel.viewHidden()
                    }.buttonStyle(SecondaryButtonStyle(isDisabled: false))

                }.padding(Padding.large)
                    .foregroundColor(Color.StartCoverDropSessionView.foregroundColor)

                customDivider()

                HStack {
                    Button("About CoverDrop") {
                        navigation.destination = .about
                        viewModel.viewHidden()
                    }.buttonStyle(FooterButtonStyle())
                    Button("Privacy policy") {
                        navigation.destination = .privacy
                        viewModel.viewHidden()
                    }.buttonStyle(FooterButtonStyle())
                }
            }
        }
    }

    var titleText: Text {
        Text("Send us a message ").foregroundColor(Color.StartCoverDropSessionView.firstLineTextForegroundColor)
            +
            Text("securely").foregroundColor(Color.StartCoverDropSessionView.secondLineTextForegroundColor)
    }
}

struct StartCoverDropSessionView_Previews: PreviewProvider {
    static var previews: some View {
        return PreviewWrapper(StartCoverDropSessionView())
    }
}
