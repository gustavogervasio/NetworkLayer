import Foundation

final class URLSessionHttpClient {

    struct UnexpectedValuesRepresentation: Error {}

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK - Private Methods
    private func createURLRequest(url: URL,
                                  method: HTTPClientMethod,
                                  headers: [String: String]? = nil) -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        return request
    }
}

extension URLSessionHttpClient: HTTPClient {

    func request(url: URL,
                 method: HTTPClientMethod = .get,
                 headers: [String: String]? = nil,
                 completion: @escaping (HTTPClientResult) -> Void) {

        let urlRequest = createURLRequest(url: url, method: method, headers: headers)
        session.dataTask(with: urlRequest) { (data, response, error) in

            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
