import CoverDropCore
import Foundation
import SwiftUI

struct InitErrorView: View {
    let error: String
    var body: some View {
        HeaderView(type: .onboarding) {
            VStack {
                Spacer()
                Text(
                    """
                    The Secure Messaging feature is currently not available.
                    Please try again later. Below we show technical information that might be helpful.
                    """
                )
                Text(error).textStyle(MonoSpacedStyle())
                Spacer()
            }.padding(10)
                .foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
        }
        .navigationBarHidden(true)
    }
}
