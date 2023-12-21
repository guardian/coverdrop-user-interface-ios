import CoverDropCore
import Foundation
import SwiftUI

struct LoadingView: View {
    var body: some View {
        HeaderView(type: .onboarding) {
            VStack {
                Spacer()
                Text("Loading...").textStyle(TitleStyle()).font(Font.headline.leading(.loose))
                ProgressView().progressViewStyle(.circular).foregroundColor(.white)
                Spacer()
            }.padding(10)
                .foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
        }
        .navigationBarHidden(true)
    }
}
