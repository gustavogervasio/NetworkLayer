import XCTest
@testable import NetworkLayer

class URLSessionHttpClient {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (Error?) -> Void) {

        session.dataTask(with: url) { (_, _, error) in
            completion(error)
        }.resume()
    }
}


class URLSessionHttpClientTests: XCTestCase {


    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_getFromURL_performsGetRequestWithURL() {

        let exp = expectation(description: "Wait get completion")
        let url = anyURL()

        makeSUT().get(from: url) { _ in }

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() {

        let exp = expectation(description: "Wait get completion")
        let url = anyURL()
        let expectedError = NSError(domain: "test", code: 1)
        URLProtocolStub.stub(error: expectedError)

        var receivedError: Error? = nil

        makeSUT().get(from: url) { result in
            receivedError = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual((receivedError as NSError?)?.code, expectedError.code)
        XCTAssertEqual((receivedError as NSError?)?.domain, expectedError.domain)
    }

    // MARK: - Helpers
    private func makeSUT() -> URLSessionHttpClient {
        return URLSessionHttpClient()
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    class URLProtocolStub: URLProtocol {

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        private struct Stub {
            let error: Error?
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            URLProtocolStub.requestObserver = nil
        }

        static func stub(error: Error?) {
            stub = Stub(error: error)
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {

            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
