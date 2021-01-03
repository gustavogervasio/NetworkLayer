protocol Target {
    var baseURL: URL { get }
    var method: HTTPClientMethod { get }
    var path: String { get }
    var headers: [String: String] { get }
}
