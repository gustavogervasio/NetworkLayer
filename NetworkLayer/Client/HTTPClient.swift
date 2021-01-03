import Foundation

internal protocol HTTPClient {

    func request(url: URL,
                 method: HTTPClientMethod,
                 body: [String: Any]?,
                 headers: [String: String]?,
                 completion: @escaping (HTTPClientResult) -> Void)
}
