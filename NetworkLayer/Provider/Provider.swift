class Provider {

    let client: HTTPClient

    init (client: HTTPClient) {
        self.client = client
    }

    func request(from target: Target, completion: @escaping (HTTPClientResult) -> Void) {

        let url = target.baseURL.appendingPathComponent(target.path)
        client.request(url: url, method: target.method, headers: target.headers) { result in
            completion(result)
        }
    }
}
