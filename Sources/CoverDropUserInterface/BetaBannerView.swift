import CoverDropCore
import Foundation
import SwiftUI

struct BetaBannerView: View {
    var imagePath: String
    var textColor: Color
    var showBetaBanner: Binding<Bool>
    var showBetaBannerAlert: Binding<Bool>

    init(showBetaBanner: Binding<Bool>, showBetaBannerAlert: Binding<Bool>) {
        imagePath = "exclamationmark.triangle.fill"
        textColor = Color.BetaBannerView.textForegroundColor
        self.showBetaBanner = showBetaBanner
        self.showBetaBannerAlert = showBetaBannerAlert
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Button(action: {
                showBetaBannerAlert.wrappedValue = true
            }) {
                HStack(alignment: .top) {
                    Image(systemName: imagePath)
                        .foregroundColor(textColor)
                        .offset(CGSize(width: 0, height: -3))

                    VStack(alignment: .leading) {
                        Text("This is test software")
                            .textStyle(ErrorBoxTitleTextStyle())
                            .foregroundColor(textColor)

                        Text("Do not send sensitive information.").textStyle(BodyStyle())
                            .padding([.trailing], Padding.medium)
                            .foregroundColor(textColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.forward")
                        .resizable()
                        .frame(width: 10, height: 15)
                        .padding(Padding.large)
                        .foregroundColor(textColor)
                }.padding([.top], Padding.medium)
                    .padding([.bottom], Padding.small)
                    .padding([.leading], Padding.xLarge)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("Dismiss beta banner")
        }
        .background(Color.BetaBannerView.backgroundColor)
    }
}

#Preview {
    BetaBannerView(showBetaBanner: .constant(true), showBetaBannerAlert: .constant(false))
}
