import XCTest
@testable import NetworkLayer

class URLSessionHttpClient {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL) {

        session.dataTask(with: url) { (_, _, _) in }.resume()
    }
}


class URLSessionHttpClientTests: XCTestCase {

    func test_getFromURL_performsGetRequestWithURL() {

        let exp = expectation(description: "Wait get completion")
        URLProtocolStub.startInterceptingRequests()

        let sut = makeSUT()

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, URL(string: "https://any-url.com")!)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        sut.get(from: URL(string: "https://any-url.com")!)

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers
    private func makeSUT() -> URLSessionHttpClient {
        return URLSessionHttpClient()
    }

    class URLProtocolStub: URLProtocol {

        private static var requestObserver: ((URLRequest) -> Void)?

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            URLProtocolStub.requestObserver = nil
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

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
