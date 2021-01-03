import XCTest
@testable import NetworkLayer

class ProviderTests: XCTestCase {

    func test_requestFromTarget_performsGetRequestWithURL() {

        let target = TargetSpy()
        let (sut, client) = makeSUT()
        let requestedURL = target.baseURL.appendingPathComponent(target.path)

        sut.request(from: target) { _ in }

        XCTAssertEqual(client.messages.count, 1)
        XCTAssertEqual(client.messages.first?.url, requestedURL)
        XCTAssertEqual(client.messages.first?.method, target.method)
        XCTAssertEqual(client.messages.first?.headers, target.headers)
    }

    func test_requestFromTarget_deliversFailureResponse() {

        let (sut, client) = makeSUT()

        let error = anyNSError()
        let result = HTTPClientResult.failure(error)

        expect(sut: sut, toCompleteWithResult: result) {
            client.complete(with: result)
        }
    }

    func test_requestFromTarget_deliversSuccessResponse() {

        let (sut, client) = makeSUT()

        let response = anyHttpURLResponse()
        let data = anyData()

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

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "test", code: 1)
    }

    private func anyData() -> Data {
        return "Any data".data(using: .utf8)!
    }

    private func anyHttpURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private struct TargetSpy: Target {

        var baseURL: URL {
            return URL(string: "https://any-url.com")!
        }

        var method: HTTPClientMethod {
            return .get
        }

        var path: String {
            return "any-path"
        }

        var headers: [String : String] {
            return ["new-header": "new-header-value"]
        }
    }

    private class URLSessionHttpClientSpy: HTTPClient {

        var messages: [(url: URL, method: HTTPClientMethod, headers: [String : String]?, completion: (HTTPClientResult) -> Void)] = []

        func request(url: URL, method: HTTPClientMethod, headers: [String : String]?, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, method, headers, completion))
        }

        func complete(with result: HTTPClientResult, at index: Int = 0) {
            messages[index].completion(result)
        }
    }
}
