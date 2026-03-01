/// A type that can inspect and mutate an `HTTPRequest` before it is sent.
///
/// Interceptors are run in the order they are registered on `URLSessionHTTPClient`.
/// Each interceptor receives the request as modified by the previous one.
///
/// Example — adding a custom header:
/// ```swift
/// struct CorrelationIDInterceptor: RequestInterceptor {
///     func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
///         request.header(HTTPHeader("X-Correlation-ID"), UUID().uuidString)
///     }
/// }
/// ```
public protocol RequestInterceptor: Sendable {
    /// Mutate or pass through the request.
    /// - Parameter request: The request about to be sent.
    /// - Returns: The (potentially modified) request to use.
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest
}

// MARK: - Interceptor chain runner

extension [any RequestInterceptor] {
    /// Runs every interceptor in order, threading the request through each one.
    func apply(to request: HTTPRequest) async throws -> HTTPRequest {
        var current = request
        for interceptor in self {
            current = try await interceptor.intercept(current)
        }
        return current
    }
}
