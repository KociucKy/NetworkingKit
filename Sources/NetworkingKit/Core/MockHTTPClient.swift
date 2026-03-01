import Foundation

/// A test-only `HTTPClient` that returns pre-configured stubs.
///
/// Use this in unit tests to avoid hitting real network endpoints:
/// ```swift
/// let mock = MockHTTPClient()
/// mock.stub(
///     HTTPRequest(method: .get, path: "/users"),
///     with: .success(HTTPResponse(statusCode: 200, data: usersJSON))
/// )
/// let service = UserService(client: mock)
/// let users = try await service.fetchUsers()
/// ```
public final class MockHTTPClient: HTTPClient, @unchecked Sendable {

    // MARK: - Types

    public typealias RequestHandler = @Sendable (HTTPRequest) async throws -> HTTPResponse

    // MARK: - State

    /// Invocations recorded in the order they were received.
    public private(set) var receivedRequests: [HTTPRequest] = []

    private var stubs: [String: Result<HTTPResponse, Error>] = [:]
    private var defaultHandler: RequestHandler?

    // MARK: - Initialiser

    public init() {}

    // MARK: - Stubbing

    /// Stubs a specific request path + method combination with a result.
    public func stub(_ request: HTTPRequest, with result: Result<HTTPResponse, Error>) {
        stubs[stubKey(for: request)] = result
    }

    /// Sets a catch-all handler for requests that have no specific stub.
    public func setDefaultHandler(_ handler: @escaping RequestHandler) {
        defaultHandler = handler
    }

    /// Removes all stubs and recorded requests.
    public func reset() {
        stubs.removeAll()
        receivedRequests.removeAll()
        defaultHandler = nil
    }

    // MARK: - HTTPClient

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        receivedRequests.append(request)

        let key = stubKey(for: request)

        if let result = stubs[key] {
            return try result.get()
        }

        if let handler = defaultHandler {
            return try await handler(request)
        }

        throw NetworkError.underlying(
            NSError(
                domain: "MockHTTPClient",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No stub found for \(request.method.rawValue) \(request.path)"]
            )
        )
    }

    // MARK: - Private

    private func stubKey(for request: HTTPRequest) -> String {
        "\(request.method.rawValue):\(request.path)"
    }
}
