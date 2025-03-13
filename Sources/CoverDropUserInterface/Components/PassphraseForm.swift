import SwiftUI

func passphraseForm(
    wordCount: Int,
    words: Binding<[String]>,
    wordVisible: Binding<[Bool]>,
    wordInvalid: [Bool]
) -> some View {
    VStack(spacing: Padding.small) {
        ForEach(0 ... wordCount - 1, id: \.self) { id in
            if wordVisible[id].wrappedValue {
                ZStack(alignment: .trailing) {
                    TextField("", text: words[id])
                        .textFieldStyle(PassphraseFieldStyle(isError: wordInvalid[id]))
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .accessibilityIdentifier("Passphrase Word \(id + 1)")
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
}
