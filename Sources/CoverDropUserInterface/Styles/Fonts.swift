//
// This file will eventually be removed once the iOS team starts using the external iOS fonts library.
//

import Foundation
import SwiftUI

public enum VerticalTrim {
    case standard
    case capToBaseline
}

public struct FontPad: ViewModifier {
    init(fontName: String, fontSize: CGFloat, lineHeight: CGFloat? = nil, relativeStyle: Font.TextStyle, verticalTrim: VerticalTrim) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.relativeStyle = relativeStyle
        self.verticalTrim = verticalTrim

        self.font = UIFont(name: fontName, size: fontSize)
    }

    let fontName: String
    let fontSize: CGFloat
    let lineHeight: CGFloat?
    let relativeStyle: Font.TextStyle

    let verticalTrim: VerticalTrim

    let font: UIFont?

    private var topValue: CGFloat {
        guard verticalTrim == .capToBaseline else { return 0 }
        guard let font else { return 0 }
        return -(font.ascender - font.capHeight)
    }

    private var bottomValue: CGFloat {
        guard verticalTrim == .capToBaseline else { return 0 }
        guard let font else { return 0 }
        return font.descender
    }

    private var lineMultiple: CGFloat {
        guard let lineHeight else { return 1 }
        guard let font else { return 1 }
        return lineHeight / font.lineHeight
    }

    public func body(content: Content) -> some View {
        content
            .font(Font.custom(fontName, size: fontSize, relativeTo: relativeStyle))
            // This is no longer supported on Xcode 15.
            // We are actively looking for a workaround.
            // ._lineHeightMultiple(lineMultiple)
            .multilineTextAlignment(.leading)
            .padding(
                .top,
                topValue
            )
            .padding(
                .bottom,
                bottomValue
            )
    }
}

public class CoverDropFonts {
    /// An enumeration representing the various font styles used in the Guardian's digital platforms.
    /// Each case corresponds to a specific font style.
    ///
    /// - Note: The font files and the CDN URLs at which they are hosted may only be used for Guardian websites or apps.
    /// All fonts are the property of Schwartzco, Inc., t/a Commercial Type (https://commercialtype.com/), and may not be reproduced without permission.
    @objc public enum GuardianFontStyle: Int, CaseIterable {
        /// Titlepiece font style in bold.
        case titlepieceBold

        /// Headline font styles.
        case headlineLight
        case headlineLightItalic
        case headlineRegular
        case headlineRegularItalic
        case headlineMedium
        case headlineMediumItalic
        case headlineSemibold
        case headlineSemiboldItalic
        case headlineBold
        case headlineBoldItalic
        case headlineBlack
        case headlineBlackItalic

        /// Text Egyptian font styles.
        case textEgyptianRegular
        case textEgyptianRegularItalic
        case textEgyptianMedium
        case textEgyptianMediumItalic
        case textEgyptianBold
        case textEgyptianBoldItalic
        case textEgyptianBlack
        case textEgyptianBlackItalic

        /// Text Sans font styles.
        case textSansRegular
        case textSansRegularItalic
        case textSansMedium
        case textSansMediumItalic
        case textSansBold
        case textSansBoldItalic
        case textSansBlack
        case textSansBlackItalic

        /// The name of the font associated with the style.
        public var fontName: String {
            GuardianFonts.fontName(for: self)
        }
    }

    @objc
    public class GuardianFonts: NSObject {
        /// Mapping from GuardianFontStyle to the font name
        fileprivate static func fontName(for style: GuardianFontStyle) -> String {
            switch style {
            case .headlineBold:
                return "GHGuardianHeadline-Bold"
            case .headlineRegularItalic:
                return "GHGuardianHeadline-RegularItalic"
            case .headlineLight:
                return "GHGuardianHeadline-Light"
            case .headlineMedium:
                return "GHGuardianHeadline-Medium"
            case .headlineRegular:
                return "GHGuardianHeadline-Regular"
            case .headlineSemibold:
                return "GHGuardianHeadline-Semibold"
            case .headlineLightItalic:
                return "GHGuardianHeadline-LightItalic"
            case .headlineMediumItalic:
                return "GHGuardianHeadline-MediumItalic"
            case .headlineSemiboldItalic:
                return "GHGuardianHeadline-SemiboldItalic"
            case .headlineBoldItalic:
                return "GHGuardianHeadline-BoldItalic"
            case .headlineBlack:
                return "GHGuardianHeadline-Black"
            case .headlineBlackItalic:
                return "GHGuardianHeadline-BlackItalic"
            case .textSansBold:
                return "GuardianTextSans-Bold"
            case .textSansBoldItalic:
                return "GuardianTextSans-BoldIt"
            case .textSansRegular:
                return "GuardianTextSans-Regular"
            case .textSansRegularItalic:
                return "GuardianTextSans-RegularIt"
            case .textSansMedium:
                return "GuardianTextSans-Medium"
            case .textSansMediumItalic:
                return "GuardianTextSans-MediumIt"
            case .textSansBlack:
                return "GuardianTextSans-Black"
            case .textSansBlackItalic:
                return "GuardianTextSans-BlackIt"
            case .textEgyptianRegular:
                return "GuardianTextEgyptian-Reg"
            case .textEgyptianRegularItalic:
                return "GuardianTextEgyptian-RegIt"
            case .textEgyptianMedium:
                return "GuardianTextEgyptian-Med"
            case .textEgyptianMediumItalic:
                return "GuardianTextEgyptian-MedIt"
            case .textEgyptianBold:
                return "GuardianTextEgyptian-Bold"
            case .textEgyptianBoldItalic:
                return "GuardianTextEgyptian-BoldIt"
            case .textEgyptianBlack:
                return "GuardianTextEgyptian-Black"
            case .textEgyptianBlackItalic:
                return "GuardianTextEgyptian-BlackIt"
            case .titlepieceBold:
                return "GTGuardianTitlepiece-Bold"
            }
        }
    }
}

public extension View {
    func font(
        _ style: CoverDropFonts.GuardianFontStyle,
        size: CGFloat,
        lineHeight: CGFloat? = nil,
        verticalTrim: VerticalTrim = .capToBaseline
    ) -> some View {
        modifier(
            FontPad(
                fontName: style.fontName,
                fontSize: size,
                lineHeight: lineHeight,
                relativeStyle: style.relativeStyle,
                verticalTrim: verticalTrim
            )
        )
    }
}

public extension CoverDropFonts.GuardianFontStyle {
    var relativeStyle: Font.TextStyle {
        switch self {
        case .headlineLight, .headlineRegular, .headlineMedium, .headlineBold, .headlineSemibold, .headlineRegularItalic, .headlineLightItalic, .headlineMediumItalic, .headlineSemiboldItalic, .headlineBoldItalic, .headlineBlack, .headlineBlackItalic:
            return .headline
        case .textSansBold, .textSansBoldItalic, .textSansRegular, .textSansRegularItalic, .textSansMedium, .textSansMediumItalic, .textSansBlack, .textSansBlackItalic:
            return .body
        case .textEgyptianRegular, .textEgyptianRegularItalic, .textEgyptianMedium, .textEgyptianMediumItalic, .textEgyptianBold, .textEgyptianBoldItalic, .textEgyptianBlack, .textEgyptianBlackItalic:
            return .body
        case .titlepieceBold:
            return .title
        }
    }
}
