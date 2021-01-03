import Foundation

internal enum HTTPClientResult: Equatable {
    case failure(Error)
    case success(Data, HTTPURLResponse)

    static func == (lhs: HTTPClientResult, rhs: HTTPClientResult) -> Bool {
        switch (lhs, rhs) {
        case let (.failure(lhsError as NSError), .failure(rhsError as NSError)):
            return lhsError.code == rhsError.code && lhsError.domain == rhsError.domain
        case let (.success(lhsData, lhsResponse), .success(rhsData, rhsResponse)):
            return lhsData == rhsData && lhsResponse == rhsResponse
        default:
            return false
        }
    }
}

internal protocol HTTPClient {

    func request(url: URL, method: HTTPClientMethod, headers: [String: String]?, completion: @escaping (HTTPClientResult) -> Void)
}

enum HTTPClientMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
