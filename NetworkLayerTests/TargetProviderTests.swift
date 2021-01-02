import XCTest
@testable import NetworkLayer

enum Method {
    case get
}

protocol Target {
    var baseURL: URL { get }
    var method: Method { get }
}

class Provider {

    let client: HTTPClient

    init (client: HTTPClient) {
        self.client = client
    }

    func request(from target: Target, completion: @escaping (HTTPClientResult) -> Void) {
        get(from: target, completion: completion)
    }

    // MARK: - Private Methods
    private func get(from target: Target, completion: @escaping (HTTPClientResult) -> Void) {
        client.get(from: target.baseURL) { result in
            completion(result)
        }
    }
}

class TargetProviderTests: XCTestCase {

    func test_requestFromTarget_performsGetRequestWithURL() {

        let target = TargetSpy()
        let (sut, client) = makeSUT()

        sut.request(from: target) { _ in }

        XCTAssertEqual(client.messages.count, 1)
        XCTAssertEqual(client.messages.first?.url, target.baseURL)
        XCTAssertEqual(client.messages.first?.method, .get)
    }

    func test_requestFromTarget_deliversFailureResponse() {

        let (sut, client) = makeSUT()

        let error = NSError(domain: "test", code: 1)
        let result = HTTPClientResult.failure(error)

        expect(sut: sut, toCompleteWithResult: result) {
            client.complete(with: result)
        }
    }

    func test_requestFromTarget_deliversSuccessResponse() {

        let (sut, client) = makeSUT()

        let url = URL(string: "https://any-url.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = "Any data".data(using: .utf8)!

        expect(sut: sut, toCompleteWithResult: HTTPClientResult.success(data, response)) {
            client.complete(with: .success(data, response))
        }
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: Provider, client: URLSessionHttpClientSpy)  {
        let client = URLSessionHttpClientSpy()
        let provider = Provider(client: client)
        return (provider, client)
    }

    private struct TargetSpy: Target {
        var baseURL: URL { return URL(string: "https://any-url.com")! }
        var method: Method { return .get }
    }

    private func expect(sut: Provider, toCompleteWithResult expectedResult: HTTPClientResult, when action:() -> Void) {

        let exp = expectation(description: "Wait request completion")
        let target = TargetSpy()

        sut.request(from: target) { result in
            XCTAssertEqual(result, expectedResult)
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }

    private class URLSessionHttpClientSpy: HTTPClient {

        var messages: [(url: URL, method: Method, completion: (HTTPClientResult) -> Void)] = []

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, .get, completion))
        }

        func complete(with result: HTTPClientResult, at index: Int = 0) {
            messages[index].completion(result)
        }
    }
}
