import Foundation
import SVGView
import SwiftUI

struct PrivacyPolicyView: View {
    @ObservedObject var navigation = Navigation.shared

    var body: some View {
        NavigationView {
            HeaderView(type: .about, dismissAction: {
                navigation.destination = .home
            }) {
                VStack(alignment: .leading) {
                    Text("Privacy Policy").textStyle(LargeTitleStyle()).font(Font.headline.leading(.loose))

                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras condimentum, massa id interdum luctus, lacus velit pulvinar enim, eu malesuada metus turpis eu quam. Nunc augue magna, sodales a scelerisque eget, interdum vitae leo. Aliquam nec elementum lacus, a accumsan purus.").textStyle(BodyStyle())
                }.padding(Padding.large)
                Spacer()
            }
        }.foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
            .navigationBarHidden(true)
    }
}
