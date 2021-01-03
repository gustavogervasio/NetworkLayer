import Foundation

internal protocol HTTPClient {

    func request(url: URL,
                 method: HTTPClientMethod,
                 headers: [String: String]?,
                 completion: @escaping (HTTPClientResult) -> Void)
}

enum HTTPClientMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
