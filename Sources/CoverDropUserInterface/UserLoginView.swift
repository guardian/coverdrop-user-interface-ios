import CoverDropCore
import CryptoKit
import Foundation
import SVGView
import SwiftUI

struct UserLoginView: View {
    @ObservedObject var viewModel: UserLoginViewModel
    @ObservedObject var navigation = Navigation.shared
    var config: ConfigType

    public init(config: ConfigType) {
        viewModel = UserLoginViewModel(config: config)
        self.config = config
    }

    var body: some View {
        HeaderView(type: .login, dismissAction: {
            navigation.destination = .home
        }) {
            VStack(alignment: .leading) {
                Text("Enter passphrase").textStyle(TitleStyle())
                Text("Enter your passphrase to unlock your secure inbox and send your first message.").textStyle(BodyStyle())

                switch viewModel.state {
                case .errorIncorrectWords:
                    InformationView(viewType: .error, title: "Incorrect word used", message: "The passphrase cannot be valid because it contains words that are not on the word list.")
                case .errorUnableToUnlock:
                    InformationView(viewType: .error, title: "Unable to unlock mailbox", message: "The passphrase you entered does not match the generated one from the previous screen.")
                case _:
                    EmptyView()
                }
                passphraseWordListTextFieldView()

                Spacer()

                Button("Confirm passphrase") {
                    Task {
                        try await viewModel.login()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(PrimaryButtonStyle(isDisabled: false))
            }.padding(Padding.medium)
                .foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
        }
    }

    private func passphraseWordListTextFieldView() -> some View {
        VStack {
            ForEach(0 ... viewModel.passphrase.count - 1, id: \.self) { id in
                if viewModel.passphraseFieldsMasked[id] {
                    ZStack(alignment: .trailing) {
                        SecureField("", text: $viewModel.passphrase[id])
                            .textContentType(.password)
                            .textFieldStyle(PassphraseFieldStyle())
                            .accessibilityIdentifier("Passphrase Word \(id + 1)")
                        Button(action: {
                            viewModel.passphraseFieldsMasked[id] = false
                        }, label: {
                            Image(systemName: "eye.fill")
                        }).accessibilityIdentifier("show \(id + 1)")
                            .padding([.trailing], Padding.medium)
                    }
                } else {
                    ZStack(alignment: .trailing) {
                        TextField("", text: $viewModel.passphrase[id])
                            .textFieldStyle(PassphraseFieldStyle())
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .accessibilityIdentifier("Passphrase Word \(id + 1)")
                        Button(action: {
                            viewModel.passphraseFieldsMasked[id] = true
                        }, label: {
                            Image(systemName: "eye.slash.fill")
                        }).accessibilityIdentifier("hide \(id + 1)")
                            .padding([.trailing], Padding.medium)
                    }
                }
            }
        }
    }
}

struct UserLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper(StatefulPreviewWrapper(false) { _ in
            UserLoginView(config: .devConfig)
        })
    }
}

extension UserLoginView {
    class UserLoginViewModel: ObservableObject {
        var config: ConfigType
        enum State {
            case inital, errorIncorrectWords, errorUnableToUnlock, errorSecureStorageNotInitialised
        }

        @Published var passphrase: [String]
        @Published var passphraseFieldsMasked: [Bool]

        @ObservedObject var secretDataRepository = SecretDataRepository.shared

        @Published var state: State = .inital

        init(config: ConfigType) {
            passphrase = UserLoginView.UserLoginViewModel.passphraseArray(passphraseWordCount: config.passphraseWordCount)
            passphraseFieldsMasked = UserLoginView.UserLoginViewModel.passphraseVisibilityArray(passphraseWordCount: config.passphraseWordCount)
            self.config = config
        }

        static func passphraseArray(passphraseWordCount: Int) -> [String] {
            return [String](repeating: "", count: passphraseWordCount)
        }

        static func passphraseVisibilityArray(passphraseWordCount: Int) -> [Bool] {
            return [Bool](repeating: true, count: passphraseWordCount)
        }

        func login() async throws {
            state = .inital

            if isPassphraseInputValid(passphrase: passphrase) {
                guard let validPassphrase = try? PasswordGenerator.checkValid(passwordInput: passphrase.joined(separator: " ")) else {
                    state = .errorIncorrectWords
                    return
                }

                let session = try? await secretDataRepository.unlock(passphrase: validPassphrase)

                if session != nil {
                    passphrase = UserLoginView.UserLoginViewModel.passphraseArray(passphraseWordCount: config.passphraseWordCount)
                    // try and decrypt the stored dead drops
                    try await DeadDropDecryptionService().decryptStoredDeadDrops()
                } else {
                    state = .errorUnableToUnlock
                }
            } else {
                state = .errorIncorrectWords
            }
        }

        func isPassphraseInputValid(passphrase: [String]) -> Bool {
            let anyEmpty: [String] = passphrase.filter {
                $0.trimmingCharacters(in: .whitespacesAndNewlines) == ""
            }
            do {
                _ = try PasswordGenerator.checkValid(passwordInput: passphrase.joined(separator: " "))
                return anyEmpty.count == 0
            } catch {
                return false
            }
        }
    }
}
