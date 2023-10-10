import CoverDropCore
import CryptoKit
import Foundation
import SVGView
import SwiftUI

struct UserLoginView: View {
    @ObservedObject var viewModel: UserLoginViewModel
    @ObservedObject var navigation = Navigation.shared

    public init() {
        viewModel = UserLoginViewModel()
    }

    var body: some View {
        HeaderView(type: .login, dismissAction: {
            navigation.destination = .home
        }) {
            VStack(alignment: .leading) {
                Text("Enter passphrase").textStyle(TitleStyle())
                Text("Enter your passphrase to unlock your inbox and proceed.").textStyle(BodyStyle())

                switch viewModel.state {
                case .errorIncorrectWords:
                    InformationView(viewType: .error, title: "Incorrect word used", message: "One of these words doesn’t match our word list. Please try again.")
                case .errorUnableToUnlock:
                    InformationView(viewType: .error, title: "Unable to unlock mailbox", message: "Either a wrong password was provided or Secure Messaging has never been used on this device.")
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

    static func passphraseArray() -> [String] {
        return [String](repeating: "", count: UserLoginView.UserLoginViewModel.passphraseLength)
    }

    static func passphraseVisibilityArray() -> [Bool] {
        return [Bool](repeating: true, count: UserLoginView.UserLoginViewModel.passphraseLength)
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
            UserLoginView()
        })
    }
}

extension UserLoginView {
    class UserLoginViewModel: ObservableObject {
        enum State {
            case inital, errorIncorrectWords, errorUnableToUnlock
        }

        public static let passphraseLength = SecureEnclave.isAvailable ? ApplicationConfig.config.passphraseLowWordCount : ApplicationConfig.config.passphraseHighWordCount

        @Published var passphrase: [String] = passphraseArray()
        @Published var passphraseFieldsMasked: [Bool] = passphraseVisibilityArray()

        @ObservedObject var secretDataRepository = SecretDataRepository.shared

        @Published var state: State = .inital

        func login() async throws {
            state = .inital

            if isPassphraseInputValid(passphrase: passphrase) {
                guard let validPassphrase = try? PasswordGenerator.checkValid(passwordInput: passphrase.joined(separator: " ")) else {
                    state = .errorIncorrectWords
                    return
                }

                let unlocked = try await secretDataRepository.unlock(passphrase: validPassphrase)

                if unlocked {
                    passphrase = UserLoginView.passphraseArray()
                    // try and decrypt the stored dead drops
                    if let date = PublicDataRepository.appConfig?.currentTime() {
                        try await DeadDropDecryptionService().decryptStoredDeadDrops(dateReceived: date)
                    }
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
