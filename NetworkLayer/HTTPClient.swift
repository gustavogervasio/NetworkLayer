import Foundation

internal enum HTTPClientResult {
    case failure(Error)
    case success(Data, HTTPURLResponse)
}

internal protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
