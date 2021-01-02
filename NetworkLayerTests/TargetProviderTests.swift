import XCTest
@testable import NetworkLayer

protocol Target {
    var baseURL: URL { get }
}

class Provider {

    let client: HTTPClient

    init (client: HTTPClient) {
        self.client = client
    }

    func get(from target: Target, completion: @escaping (HTTPClientResult) -> Void) {
        client.get(from: target.baseURL) { result in
            completion(result)
        }
    }
}

class TargetProviderTests: XCTestCase {

    func test_getFromTarget_performsGetRequestWithURL() {

        let target = TargetSpy()
        let (sut, client) = makeSUT()

        sut.get(from: target) { _ in }

        XCTAssertEqual(client.messages.count, 1)
        XCTAssertEqual(client.messages.first?.url, target.baseURL)
    }

    func test_getFromTarget_deliversSuccessResponse() {

        let exp = expectation(description: "Wait get completion")
        let target = TargetSpy()
        let (sut, client) = makeSUT()

        var receivedResult: HTTPClientResult? = nil
        sut.get(from: target) { result in
            receivedResult = result
            exp.fulfill()
        }

        client.completeWithSuccess()

        wait(for: [exp], timeout: 1.0)

        XCTAssertNotNil(receivedResult)
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: Provider, client: URLSessionHttpClientSpy)  {
        let client = URLSessionHttpClientSpy()
        let provider = Provider(client: client)
        return (provider, client)
    }

    private struct TargetSpy: Target {
        var baseURL: URL { return URL(string: "https://any-url.com")! }
    }

    private class URLSessionHttpClientSpy: HTTPClient {

        var messages: [(url: URL, completion: (HTTPClientResult) -> Void)] = []

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func completeWithSuccess(at index: Int = 0) {
            let url = URL(string: "https://any-url.com")!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "Any data".data(using: .utf8)!
            messages[index].completion(HTTPClientResult.success(data, response))
        }
    }
}
