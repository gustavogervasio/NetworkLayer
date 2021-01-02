import Foundation
import XCTest

protocol NetworkTarget {
    var baseURL: URL { get }
}

class TargetProvider {

    let client: HTTPClient

    init (client: HTTPClient) {
        self.client = client
    }

    func get(from target: NetworkTarget) {
        client.get(from: target.baseURL) { _ in }
    }
}

class TargetProviderTests: XCTestCase {

    func test_getFromTarget_performsGetRequestWithURL() {

        let target = Target()
        let (sut, client) = makeSUT()

        sut.get(from: target)

        XCTAssertEqual(client.getRequests.count, 1)
        XCTAssertEqual(client.getRequests.first, target.baseURL)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: TargetProvider, client: URLSessionHttpClientSpy)  {
        let client = URLSessionHttpClientSpy()
        let provider = TargetProvider(client: client)
        return (provider, client)
    }

    private struct Target: NetworkTarget {
        var baseURL: URL { return URL(string: "https://any-url.com")! }
    }

    private class URLSessionHttpClientSpy: HTTPClient {

        var getRequests: [URL] = []

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            getRequests.append(url)
        }
    }
}
