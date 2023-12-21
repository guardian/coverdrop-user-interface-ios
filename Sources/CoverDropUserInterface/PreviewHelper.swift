import CoverDropCore
import Foundation

enum PreviewHelper {
    static func initSendingQueue() {
        Task {
            let verifiedPublicKeys = PublicKeysHelper.shared.testKeys
            if let coverMessageFactory = try? PublicDataRepository.getCoverMessageFactory(verifiedPublicKeys: verifiedPublicKeys) {
                try? await PrivateSendingQueueRepository.shared.loadOrInitialiseQueue(coverMessageFactory: coverMessageFactory)
            }
        }
    }
}
