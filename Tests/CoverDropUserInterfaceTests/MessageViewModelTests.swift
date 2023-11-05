@testable import CoverDropCore
@testable import CoverDropUserInterface
import XCTest

final class MessageViewModelTests: XCTestCase {
    override func setUp() async throws {
        let config = ApplicationConfig.config
        PublicDataRepository.setup(config)
    }

    func testReady() async {
        let testKeys = PublicKeysHelper.shared.testKeys
        let sut = await ConversationViewModel(verifiedPublicKeys: testKeys)

        // the view model should be `ready` upon initialization
        let state = await sut.state
        XCTAssert(state == .ready)

        let recipients = await sut.recipients
        XCTAssert(recipients != nil)
    }

    @MainActor
    func testMessageLengthWithShortMessage() {
        // GIVEN a `MessageViewModel`
        let testKeys = PublicKeysHelper.shared.testKeys
        let sut = ConversationViewModel(verifiedPublicKeys: testKeys)

        // WHEN a short message is added
        sut.topic = "This is a short topic"
        sut.message = "This is a short message"

        // THEN the message is not too long
        XCTAssertFalse(sut.messageIsTooLong)
    }

    @MainActor
    func testMessageLengthWithLongTopic() {
        // GIVEN a `MessageViewModel`
        let testKeys = PublicKeysHelper.shared.testKeys
        let sut = ConversationViewModel(verifiedPublicKeys: testKeys)

        // WHEN a long topic is added
        let shortTopic = "This will be an incredibly long topic."
        sut.topic = shortTopic

        for _ in 1 ... 6000 {
            sut.topic.append(contentsOf: shortTopic)
        }

        sut.message = "This is a short message"

        // THEN the complete message too long
        XCTAssert(sut.messageIsTooLong)
    }

    @MainActor
    func testMessageLengthWithLongMessage() {
        // GIVEN a `MessageViewModel`
        let testKeys = PublicKeysHelper.shared.testKeys
        let sut = ConversationViewModel(verifiedPublicKeys: testKeys)

        // WHEN a long message is added
        let shortMessage = "This will be an incredibly long message."
        sut.message = shortMessage

        for _ in 1 ... 6000 {
            sut.message.append(contentsOf: shortMessage)
        }

        sut.topic = "This is a short topic"

        // THEN the complete message too long
        XCTAssert(sut.messageIsTooLong)
    }
}
