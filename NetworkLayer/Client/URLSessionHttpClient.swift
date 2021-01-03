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
                                  body: [String: Any]?,
                                  headers: [String: String]?) -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        if let body = body as? [String: String] {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let httpBody = try? JSONEncoder().encode(body)
            request.httpBody = httpBody
        }
        return request
    }
}

extension URLSessionHttpClient: HTTPClient {

    func request(url: URL,
                 method: HTTPClientMethod = .get,
                 body: [String: Any]? = nil,
                 headers: [String: String]? = nil,
                 completion: @escaping (HTTPClientResult) -> Void) {

        let urlRequest = createURLRequest(url: url, method: method, body: body, headers: headers)
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
