import Foundation

/// The raw result of an HTTP request.
public struct HTTPResponse: Sendable {

    // MARK: - Properties

    /// The HTTP status code (e.g. 200, 404).
    public let statusCode: Int
    /// Raw response body.
    public let data: Data
    /// Response headers keyed by lowercase field name.
    public let headers: [String: String]

    // MARK: - Convenience

    /// Returns `true` for status codes in the 200–299 range.
    public var isSuccess: Bool {
        (200..<300).contains(statusCode)
    }

    // MARK: - Initialiser

    public init(statusCode: Int, data: Data, headers: [String: String] = [:]) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
    }
}
