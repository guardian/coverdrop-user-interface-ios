import Foundation
import SVGView
import SwiftUI

struct ChevronButtonData {
    var text: String
    var target: HelpScreenContent
}

struct ChevronButtonList: View {
    @Binding var navPath: NavigationPath
    @State var buttonData = [ChevronButtonData]()

    func navigateToHelp(contentVariant: HelpScreenContent) {
        navPath.append(Destination.help(contentVariant: contentVariant))
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(buttonData.indices, id: \.self) { index in
                    let data = buttonData[index]
                    Button(action: { navigateToHelp(contentVariant: data.target) }) {
                        HStack {
                            Text(data.text)
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .resizable()
                                .fontWeight(.semibold)
                                .frame(width: 7, height: 11)
                                .foregroundColor(Color.ChevronButtonList.chevronColor)
                                .padding([.trailing], Padding.small)
                        }
                    }
                    if index < buttonData.count - 1 {
                        Rectangle()
                            .fill(Color.ChevronButtonList.dividerColor)
                            .frame(height: 1)
                            .padding(.vertical, Padding.small)
                    }
                }
            }.padding(.horizontal, Padding.medium)
                .padding(.vertical, Padding.small)
        }.background(Color.ChevronButtonList.backgroundColor)
            .cornerRadius(CornerRadius.medium)
    }
}

struct AboutCoverDropView: View {
    @Binding var navPath: NavigationPath

    func navigateToHelp(contentVariant: HelpScreenContent) {
        navPath.append(Destination.help(contentVariant: contentVariant))
    }

    var body: some View {
        NavigationView {
            HeaderView(type: .about, dismissAction: {
                if !navPath.isEmpty {
                    navPath.removeLast()
                }
            }) {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("About Secure Messaging")
                            .textStyle(LargeTitleStyle())
                            .font(Font.headline.leading(.loose))

                        Text("What this is for")
                            .textStyle(GuardianHeaderTextStyle())
                            .padding([.top], Padding.large)
                            .padding([.bottom], Padding.small)
                        ChevronButtonList(navPath: $navPath, buttonData: [
                            ChevronButtonData(
                                text: "Why we made Secure Messaging",
                                target: .whyWeMadeSecureMessaging
                            ),
                            ChevronButtonData(
                                text: "How Secure Messaging works",
                                target: .howSecureMessagingWorks
                            ),
                            ChevronButtonData(
                                text: "FAQs",
                                target: .faq
                            ),
                            ChevronButtonData(
                                text: "Privacy policy",
                                target: .privacyPolicy
                            )
                        ])

                        Text("Getting started")
                            .textStyle(GuardianHeaderTextStyle())
                            .padding([.top], Padding.large)
                            .padding([.bottom], Padding.small)
                        ChevronButtonList(navPath: $navPath, buttonData: [
                            ChevronButtonData(
                                text: "Craft your first message",
                                target: .craftMessage
                            ),
                            ChevronButtonData(
                                text: "Keeping passphrases safe",
                                target: .keepingPassphraseSafe
                            )
                        ])

                        Text("As the conversation progresses")
                            .textStyle(GuardianHeaderTextStyle())
                            .padding([.top], Padding.large)
                            .padding([.bottom], Padding.small)
                        ChevronButtonList(navPath: $navPath, buttonData: [
                            ChevronButtonData(
                                text: "What to expect as a reply",
                                target: .replyExpectations
                            ),
                            ChevronButtonData(
                                text: "Source protection",
                                target: .sourceProtection
                            )
                        ])
                    }.padding(Padding.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                Spacer()
            }
        }.foregroundColor(Color.StartCoverDropSessionView.foregroundColor)
            .navigationBarHidden(true)
    }
}
