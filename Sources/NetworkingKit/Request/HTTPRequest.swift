import Foundation

/// A value type representing a complete HTTP request.
///
/// Build a request using the initialiser or the convenience builder methods:
/// ```swift
/// let request = HTTPRequest(method: .get, path: "/users")
///     .header(.accept, HTTPHeader.Accept.json)
///     .queryItem("page", "1")
/// ```
public struct HTTPRequest: Sendable {

    // MARK: - Properties

    public var method: HTTPMethod
    /// Path relative to the base URL configured in `URLSessionHTTPClient`.
    /// Must start with `/`.
    public var path: String
    public var headers: [HTTPHeader: String]
    public var queryItems: [URLQueryItem]
    /// Raw body data. Use the `body(encodable:encoder:)` helper to encode `Encodable` values.
    public var body: Data?

    // MARK: - Initialiser

    public init(
        method: HTTPMethod,
        path: String,
        headers: [HTTPHeader: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }

    // MARK: - Builder helpers

    /// Returns a copy of the request with the given header set.
    public func header(_ header: HTTPHeader, _ value: String) -> HTTPRequest {
        var copy = self
        copy.headers[header] = value
        return copy
    }

    /// Returns a copy of the request with the given query item appended.
    public func queryItem(_ name: String, _ value: String) -> HTTPRequest {
        var copy = self
        copy.queryItems.append(URLQueryItem(name: name, value: value))
        return copy
    }

    /// Returns a copy of the request with the body set to the JSON-encoded value.
    /// Automatically adds `Content-Type: application/json` if not already present.
    public func body<T: Encodable>(encodable value: T, encoder: JSONEncoder = JSONEncoder()) throws -> HTTPRequest {
        var copy = self
        copy.body = try encoder.encode(value)
        if copy.headers[.contentType] == nil {
            copy.headers[.contentType] = HTTPHeader.ContentType.json
        }
        return copy
    }
}
