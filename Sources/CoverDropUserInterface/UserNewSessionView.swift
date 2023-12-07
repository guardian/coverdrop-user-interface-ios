import CoverDropCore
import CryptoKit
import Foundation
import SVGView
import SwiftUI

enum NewSessionError: Error {
    case failedToGeneratePassphrase
}

struct UserNewSessionView: View {
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var viewModel: UserNewSessionView.UserNewSessionViewModel = UserNewSessionViewModel()

    var body: some View {
        HeaderView(type: .newPassphrase, dismissAction: {
            navigation.destination = .onboarding
        }) {
            VStack(alignment: .leading) {
                Text("Remember Passphrase").textStyle(TitleStyle())
                Text("Your passphrase will be used to access your conversation. You’ll need to remember this.").textStyle(BodyStyle())

                passphraseWordListView()

                // Show the hide passphrase button when the text is revealed
                if case .shown = viewModel.currentState {
                    HStack(alignment: .top) {
                        Spacer()
                        Button(action: {
                            self.viewModel.currentState = .hidden
                        }, label: {
                            Label("Hide passphrase", systemImage: "eye.slash.fill")
                        }).buttonStyle(HideButtonStyle())
                    }
                }

                Spacer()
                switch viewModel.currentState {
                case .shown:
                    Button("I have remembered my passphrase") {
                        Task {
                            await viewModel.createNewStorage()
                            viewModel.clearPassphrase()
                            navigation.destination = .newConversation
                        }
                    }.buttonStyle(PrimaryButtonStyle(isDisabled: false))
                case .hidden:
                    Button(action: {
                        self.viewModel.currentState = .shown
                    }, label: {
                        Label("Reveal passphrase", systemImage: "eye.fill")
                    }).buttonStyle(PrimaryButtonStyle(isDisabled: false))
                case let .error(error):
                    Text("Error: \(error.localizedDescription)")
                }

            }.padding(Padding.large)
            .foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
            .onAppear {
                self.viewModel.currentState = .hidden
                do {
                    try viewModel.newPassphrase()
                } catch {
                    self.viewModel.currentState = .error(NewSessionError.failedToGeneratePassphrase)
                }

                tertiaryButton(action: {
                    navigation.destination = .login
                },
                text: "I already have a passphrase")
            }
        }
    }

    func passphraseWordListView() -> some View {
        VStack {
            ForEach(Array(self.viewModel.passphraseWords.enumerated()), id: \.element) { id, word in
                switch viewModel.currentState {
                case .shown:
                    Text(word)
                        .textStyle(PassphraseTextStyle())
                        .accessibilityIdentifier("Word \(id + 1)")
                case .hidden:
                    Text("●●●●●●").textStyle(PassphraseTextStyle())
                case let .error(error):
                    Text("Error: \(error.localizedDescription)")
                }
            }.frame(maxWidth: .infinity)
        }.background(Color.UserNewSessionView.wordListBackgroundColor).frame(maxWidth: .infinity)
    }
}

extension UserNewSessionView {
    @MainActor class UserNewSessionViewModel: ObservableObject {
        enum State {
            case shown, hidden
            case error(Error)
        }

        @Published var currentState: State = .hidden

        @Published private(set) var passphrase: ValidPassword? {
            didSet {
                passphraseWords = (passphrase?.password.split(separator: " ").map { String($0) } ?? [])
            }
        }

        @Published private(set) var passphraseWords: [String] = []

        public init() {}

        func newPassphrase() throws {
            let newPassphrase = EncryptedStorage.newStoragePassphrase()
            passphrase = newPassphrase
        }

        func clearPassphrase() {
            passphrase = nil
        }

        func createNewStorage() async {
            do {
                if let validPassphrase = passphrase {
                    _ = try await EncryptedStorage.createOrResetStorageWithPassphrase(passphrase: validPassphrase)
                } else {
                    currentState = .error("Missing Passphrase")
                }
            } catch {
                currentState = .error(error)
            }
        }
    }
}
