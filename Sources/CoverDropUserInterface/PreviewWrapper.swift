import Foundation
import GuardianFonts
import SwiftUI

public struct PreviewWrapper<Value: View>: View {
    private let viewToPreview: Value

    init(_ viewToPreview: Value) {
        GuardianFonts.registerFonts()
        self.viewToPreview = viewToPreview
    }

    public var body: some View {
        return viewToPreview
    }
}
