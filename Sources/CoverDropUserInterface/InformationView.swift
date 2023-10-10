import Foundation
import SwiftUI

struct InformationView: View {
    enum ViewType {
        case error, info
    }

    var viewType: ViewType
    var title: String
    var message: String
    var imagePath: String
    var textColor: Color
    var strokeColor: Color

    init(viewType: ViewType, title: String, message: String) {
        self.viewType = viewType
        self.title = title
        self.message = message
        switch viewType {
        case .error:
            imagePath = "exclamationmark.triangle.fill"
            textColor = Color.UserLoginView.errorMessageForegroundColor
            strokeColor = Color.UserLoginView.errorMessageStrokeColor
        case .info:
            imagePath = "info.circle.fill"
            textColor = Color.NewMessageView.messageInformationColor
            strokeColor = Color.NewMessageView.messageInformationStrokeColor
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text("\(Image(systemName: imagePath))")
                    .foregroundColor(strokeColor)
                VStack(alignment: .leading) {
                    Text("\(title)")
                        .textStyle(ErrorBoxTitleTextStyle())
                        .padding([.bottom], Padding.xSmall)
                        .foregroundColor(textColor)

                    Text(message).textStyle(BodyStyle())
                        .padding([.trailing], Padding.medium)
                        .foregroundColor(textColor)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding([.leading, .top, .bottom], Padding.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 1))
        )
        .padding([.bottom], Padding.large)
    }
}
