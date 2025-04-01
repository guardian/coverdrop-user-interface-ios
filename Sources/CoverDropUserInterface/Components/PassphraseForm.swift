import Foundation
import SwiftUI

func passphraseForm(
    wordCount: Int,
    words: Binding<[String]>,
    wordVisible: Binding<[Bool]>,
    wordInvalid: [Bool],
    passwordFieldFocus: FocusState<PasswordField?>.Binding
) -> some View {
    VStack(spacing: Padding.small) {
        ForEach(0 ... wordCount - 1, id: \.self) { id in

            var passwordFieldFocusValue: PasswordField {
                if id == 0 { .password1 } else if id == 1 { .password2 } else { .password3 }
            }

            if wordVisible[id].wrappedValue {
                ZStack(alignment: .trailing) {
                    TextField("", text: words[id])
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(PassphraseFieldStyle(isError: wordInvalid[id]))
                        .accessibilityIdentifier("Passphrase Word \(id + 1)")
                        .focused(
                            passwordFieldFocus,
                            equals: passwordFieldFocusValue
                        )
                        .submitLabel(id == wordCount - 1 ? .done : .next)

                    Button(action: {
                        wordVisible[id].wrappedValue = false
                    }, label: {
                        Image(systemName: "eye.slash.fill")
                    }).accessibilityIdentifier("show \(id + 1)")
                        .padding([.trailing], Padding.medium)
                        .frame(height: 25)
                }
            } else {
                ZStack(alignment: .trailing) {
                    SecureField("", text: words[id])
                        .textFieldStyle(PassphraseFieldStyle(isError: wordInvalid[id]))
                        .textContentType(.password)
                        .accessibilityIdentifier("Passphrase Word \(id + 1)")
                        .focused(passwordFieldFocus, equals: passwordFieldFocusValue)
                        .submitLabel(id == wordCount - 1 ? .done : .next)
                    Button(action: {
                        wordVisible[id].wrappedValue = true
                    }, label: {
                        Image(systemName: "eye.fill")
                    }).accessibilityIdentifier("hide \(id + 1)")
                        .padding([.trailing], Padding.medium)
                        .frame(height: 25)
                }
            }
        }
    }.padding(.bottom, Padding.small)
        .onChange(of: words.wrappedValue) { _, newValue in
            // This fixes an issue with autocorrect that always adds a space at the end of a corrected word
            words.wrappedValue = newValue.map { value in
                return value.trimmingCharacters(in: .whitespaces)
            }
        }
        .onSubmit {
            switch passwordFieldFocus.wrappedValue {
            case .password1:
                passwordFieldFocus.wrappedValue = .password2
            case .password2:
                passwordFieldFocus.wrappedValue = .password3
            default:
                passwordFieldFocus.wrappedValue = nil
            }
        }
}
