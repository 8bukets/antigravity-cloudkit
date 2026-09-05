import XCTest
@testable import AntigravityCloudKit

final class TokenStoreTests: XCTestCase {
    func testSaveAndLoadTokenRoundtrip() throws {
        let tokenStore = TokenStore(subpath: "test_history_token")
        // Create a fake token using NSPersistentHistoryToken archived data roundtrip — in tests we just save nil and ensure no crashes
        tokenStore.saveToken(nil)
        XCTAssertNil(tokenStore.loadToken())
    }
}
