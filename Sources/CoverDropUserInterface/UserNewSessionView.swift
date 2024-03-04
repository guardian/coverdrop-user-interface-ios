import CoverDropCore
import CryptoKit
import Foundation
import SVGView
import SwiftUI

enum NewSessionError: Error {
    case failedToGeneratePassphrase
}

struct UserNewSessionView: View {
    var config: CoverDropConfig
    @ObservedObject var navigation = Navigation.shared
    @ObservedObject var viewModel: UserNewSessionView.UserNewSessionViewModel = UserNewSessionViewModel()

    var body: some View {
        HeaderView(type: .newPassphrase, dismissAction: {
            navigation.destination = .onboarding
        }) {
            VStack(alignment: .leading) {
                Text("Remember Passphrase").textStyle(TitleStyle())
                Text(
                    """
                    You will always need this passphrase to access your secure inbox.
                    So please ensure you memorise it.
                    It must be entered in the correct order with the correct spelling.
                    """
                )
                .textStyle(BodyStyle())

                passphraseWordListView()

                // Show the hide passphrase button when the text is revealed
                if case .shown = viewModel.passphraseState {
                    HStack(alignment: .top) {
                        Spacer()
                        Button(action: {
                            self.viewModel.passphraseState = .hidden
                        }, label: {
                            Label("Hide passphrase", systemImage: "eye.slash.fill")
                        }).buttonStyle(HideButtonStyle())
                            .accessibilityIdentifier("Hide passphrase")
                    }
                }

                Spacer()
                switch viewModel.passphraseState {
                case .shown, .submitted:
                    AsyncActionButton(
                        buttonText: "I have remembered my passphrase",
                        isInProgress: viewModel.isSubmitted
                    ) {
                        await viewModel.createNewStorage()
                        viewModel.clearPassphrase()
                        navigation.destination = .newConversation
                    }
                case .hidden:
                    Button(action: {
                        self.viewModel.passphraseState = .shown
                    }, label: {
                        Label("Reveal passphrase", systemImage: "eye.fill")
                    }).buttonStyle(PrimaryButtonStyle(isDisabled: false))
                case let .error(error):
                    Text("Error: \(error.localizedDescription)")
                }

            }.padding(Padding.large)
                .foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
            tertiaryButton(action: {
                               navigation.destination = .login
                           },
                           text: "I already have a passphrase")
        }
    }

    func passphraseWordListView() -> some View {
        VStack {
            if let passphraseWords = viewModel.passphraseWords {
                ForEach(Array(passphraseWords.enumerated()), id: \.element) { id, word in
                    switch viewModel.passphraseState {
                    case .shown, .submitted:
                        Text(word)
                            .textStyle(PassphraseTextStyle())
                            .accessibilityIdentifier("Word \(id + 1)")
                    case .hidden:
                        Text("●●●●●●").textStyle(PassphraseTextStyle())
                    case let .error(error):
                        Text("Error: \(error.localizedDescription)")
                    }

                }.frame(maxWidth: .infinity)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(.white)
                    .padding(Padding.large)
            }
        }.background(Color.UserNewSessionView.wordListBackgroundColor)
            .frame(maxWidth: .infinity)
            .onAppear {
                Task {
                    viewModel.initializeWithNewPassphrase(passphraseWordCount: config.passphraseWordCount)
                }
            }
    }
}

extension UserNewSessionView {
    @MainActor class UserNewSessionViewModel: ObservableObject {
        enum State {
            case shown, hidden, submitted
            case error(Error)
        }

        @Published var passphraseState: State = .hidden

        @Published private(set) var passphrase: ValidPassword? {
            didSet {
                passphraseWords = (passphrase?.password.split(separator: " ").map { String($0) } ?? [])
            }
        }

        @Published private(set) var passphraseWords: [String]?

        public init() {}

        var isSubmitted: Bool {
            if case .submitted = passphraseState {
                return true
            } else { return false }
        }

        func initializeWithNewPassphrase(passphraseWordCount: Int) {
            passphraseState = .hidden
            newPassphrase(passphraseWordCount: passphraseWordCount)
        }

        func newPassphrase(passphraseWordCount: Int) {
            let newPassphrase = EncryptedStorage.newStoragePassphrase(passphraseWordCount: passphraseWordCount)
            passphrase = newPassphrase
        }

        func clearPassphrase() {
            passphrase = nil
        }

        func createNewStorage() async {
            passphraseState = .submitted
            do {
                if let validPassphrase = passphrase {
                    _ = try await EncryptedStorage.createOrResetStorageWithPassphrase(passphrase: validPassphrase)
                } else {
                    passphraseState = .error("Missing Passphrase")
                }
            } catch {
                passphraseState = .error(error)
            }
        }
    }
}
