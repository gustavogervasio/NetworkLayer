import XCTest
@testable import NetworkLayer

class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_requestFromURL_failsOnRequestError() {
        let expectedError = anyNSError()

        let result = resultErrorFor(data: nil, response: nil, error: expectedError)

        XCTAssertEqual((result as NSError?)?.code, expectedError.code)
        XCTAssertEqual((result as NSError?)?.domain, expectedError.domain)
    }

    func test_requestFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHttpURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHttpURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHttpURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHttpURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHttpURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHttpURLResponse(), error: nil))
    }

    func test_requestFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHttpURLResponse()

        let result = resultValuesFor(data: data, response: response, error: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.data, data)
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
    }

    func test_requestFromURL_suceedsWithEmptyDataOnHttpURLResponseWithNilData() {
        let response = anyHttpURLResponse()

        let result = resultValuesFor(data: nil, response: anyHttpURLResponse(), error: nil)

        let emptyData = Data()
        XCTAssertEqual(result?.data, emptyData)
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
    }

    func test_requestFromURL_withoutMethod_performsGetRequest() {

        let url = anyURL()
        let request = requestFor(url: anyURL())

        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
    }

    func test_requestFromURL_withPostMethod_performsPostRequest() {

        let url = anyURL()
        let request = requestFor(url: url, method: .post)

        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
    }

    func test_requestFromURL_withPutMethod_performsPutRequest() {

        let url = anyURL()
        let request = requestFor(url: url, method: .put)

        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
    }

    func test_requestFromURL_withDeleteMethod_performsDeleteRequest() {

        let url = anyURL()
        let request = requestFor(url: url, method: .delete)

        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
    }

    func test_requestFromURL_withHeader_performsRequest() {

        let headers = ["new-header": "new-header-value"]

        let request = requestFor(url: anyURL(), headers: headers)

        XCTAssertEqual(request.allHTTPHeaderFields, headers)
    }

    func test_requestFromURL_withBody_performsRequest() {

        let body = ["body": "body-value"]
        let json = try? JSONEncoder().encode(body)

        let request = requestFor(url: anyURL(), method: .post, body: body)

        XCTAssertEqual(request.httpBodyStream?.readfully(), json)
    }

    func test_requestFromURL_withBody_addsContentTypeHeader() {

        let request = requestFor(url: anyURL(), body: ["body": "body-value"])

        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
    }

    // MARK: - Helpers
    private func makeSUT() -> URLSessionHTTPClient {

        let session: URLSession = {
            let configuration: URLSessionConfiguration = {
                let configuration = URLSessionConfiguration.ephemeral
                configuration.protocolClasses = [URLProtocolStub.self]
                return configuration
            }()
            let session = URLSession(configuration: configuration)
            return session
        }()

        return URLSessionHTTPClient(session: session)
    }

    private func requestFor(url: URL,
                            method: HTTPClientMethod = .get,
                            body: [String: Any]? = nil,
                            headers: [String: String]? = nil) -> URLRequest {

        let exp = expectation(description: "Wait request completion")

        makeSUT().request(url: url, method: method, body: body, headers: headers) { _ in }

        var observedRequest: URLRequest!
        URLProtocolStub.observeRequests { request in
            observedRequest = request
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        return observedRequest
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "test", code: 1)
    }

    private func nonHttpURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func anyData() -> Data {
        return "Any data".data(using: .utf8)!
    }

    private func anyHttpURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: NSError?) -> Error? {

        let exp = expectation(description: "Wait get completion")

        URLProtocolStub.stub(data: data, response: response, error: error)

        var receivedResult: HTTPClientResult? = nil

        makeSUT().request(url: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        switch receivedResult {
        case let .failure(error):
            return error
        default:
            return nil
        }
    }

    private func resultValuesFor(data: Data?, response: URLResponse?, error: NSError?) -> (data: Data, response: HTTPURLResponse)? {

        let exp = expectation(description: "Wait get completion")

        URLProtocolStub.stub(data: data, response: response, error: error)

        var receivedResult: HTTPClientResult? = nil

        makeSUT().request(url: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        switch receivedResult {
        case let .success(data, response):
            return (data, response)
        default:
            return nil
        }
    }

    class URLProtocolStub: URLProtocol {

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            URLProtocolStub.requestObserver = nil
            URLProtocolStub.stub = nil
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
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

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}

private extension InputStream {
    func readfully() -> Data {
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        open()
        var amount = 0
        repeat {
            amount = read(&buffer, maxLength: buffer.count)
            if amount > 0 {
                result.append(buffer, count: amount)
            }
        } while amount > 0
        close()
        return result
    }
}
