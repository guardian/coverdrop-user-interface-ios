import CoverDropCore
@testable import CoverDropUserInterface
import Sodium
import XCTest

@MainActor
final class ConversationViewModelTests: XCTestCase {
    func testMessageLengthProgressPercentage() throws {
        PublicDataRepository.setup(ApplicationConfig.config)
        let conversationViewModel = ConversationViewModel(verifiedPublicKeys: PublicDataRepository.shared.verifiedPublicKeysData)
        guard let percentage = try? conversationViewModel.messageLengthProgressPercentage.get() else {
            XCTFail("Could not get percentage")
            return
        }
        XCTAssertTrue(percentage == 0)
        conversationViewModel.message = "This is a test message"

        guard let percentage2 = try? conversationViewModel.messageLengthProgressPercentage.get() else {
            XCTFail("Could not get percentage")
            return
        }

        XCTAssertTrue(percentage2 >= 5 && percentage2 <= 15)
        conversationViewModel.message = """
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer dolor
                nulla, ornare et tristique imperdiet, dictum sit amet velit. Curabitur pharetra erat sed
                neque interdum, non mattis tortor auctor. Curabitur eu ipsum ac neque semper eleifend.
                Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
                Integer erat mi, ultrices nec arcu ut, sagittis sollicitudin est. In hac habitasse
                platea dictumst. Sed in efficitur elit. Curabitur nec commodo elit. Aliquam tincidunt
                rutrum nisl ut facilisis. Aenean ornare ut mauris eget lacinia. Mauris a felis quis orci
                auctor varius sit amet eget est. Curabitur a urna sit amet diam sagittis aliquet eget eu
                sapien. Curabitur a pharetra purus.
                Nulla facilisi. Suspendisse potenti. Morbi mollis aliquet sapien sed faucibus. Donec
                aliquam nibh nibh, ac faucibus felis aliquam at. Pellentesque egestas enim sem, eu
                tempor urna posuere eget. Cras fermentum commodo neque ac gravida.
        """

        if case let .failure(tooLongError) = conversationViewModel.messageLengthProgressPercentage {
            XCTAssertTrue(tooLongError == .textTooLong)
        } else {
            XCTFail("Error not correctly thrown")
        }
    }
}
