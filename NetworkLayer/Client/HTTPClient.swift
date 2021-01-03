import Foundation

internal protocol HTTPClient {

    func request(url: URL,
                 method: HTTPClientMethod,
                 headers: [String: String]?,
                 completion: @escaping (HTTPClientResult) -> Void)
}
