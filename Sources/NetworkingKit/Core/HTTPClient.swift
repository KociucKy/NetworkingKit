/// The core networking abstraction.
///
/// Depend on this protocol throughout your app rather than on any concrete type,
/// so you can swap in `MockHTTPClient` during tests.
///
/// ```swift
/// final class UserService {
///     private let client: any HTTPClient
///
///     init(client: any HTTPClient) {
///         self.client = client
///     }
///
///     func fetchUsers() async throws -> [User] {
///         let request = HTTPRequest(method: .get, path: "/users")
///         let response = try await client.send(request)
///         return try response.decode([User].self)
///     }
/// }
/// ```
public protocol HTTPClient: Sendable {
    /// Sends the request and returns the raw HTTP response.
    /// - Throws: `NetworkError` on failure.
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}
