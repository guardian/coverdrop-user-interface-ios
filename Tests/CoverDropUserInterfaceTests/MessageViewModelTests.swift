@testable import CoverDropCore
@testable import CoverDropUserInterface
import XCTest

final class MessageViewModelTests: XCTestCase {
    override func setUp() async throws {
        let config = StaticConfig.devConfig
        PublicDataRepository.setup(config)
    }

    func testReady() async {
        let sut = await ConversationViewModel(
            verifiedPublicKeys: PublicKeysHelper.shared.testKeys,
            config: StaticConfig.devConfig
        )

        // the view model should be `ready` upon initialization
        let state = await sut.state
        XCTAssert(state == .ready)

        let recipients = await sut.recipients
        XCTAssert(recipients != nil)
    }

    @MainActor
    func testMessageLengthWithShortMessage() async {
        // GIVEN a `MessageViewModel`
        let sut = ConversationViewModel(
            verifiedPublicKeys: PublicKeysHelper.shared.testKeys,
            config: StaticConfig.devConfig
        )

        // WHEN a short message is added
        sut.message = "This is a short message"

        // THEN the message is not too long
        XCTAssertFalse(sut.messageIsTooLong)
    }

    @MainActor
    func testMessageLengthWithLongMessage() async {
        // GIVEN a `MessageViewModel`
        let sut = ConversationViewModel(
            verifiedPublicKeys: PublicKeysHelper.shared.testKeys,
            config: StaticConfig.devConfig
        )

        // WHEN a long message is added
        let shortMessage = "This will be an incredibly long message."
        sut.message = shortMessage

        for _ in 1 ... 6000 {
            sut.message.append(contentsOf: shortMessage)
        }

        // THEN the complete message too long
        XCTAssert(sut.messageIsTooLong)
    }
}
