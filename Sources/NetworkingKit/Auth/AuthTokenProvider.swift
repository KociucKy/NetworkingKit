/// Provides a valid authentication token for outgoing requests.
///
/// Implement this protocol in your app to supply Bearer tokens. The client
/// calls `validToken()` before every request, so you can transparently
/// refresh an expired token inside the implementation.
///
/// Example:
/// ```swift
/// actor MyTokenProvider: AuthTokenProvider {
///     func validToken() async throws -> String {
///         // refresh if needed, then return the current token
///         return storedToken
///     }
/// }
/// ```
public protocol AuthTokenProvider: Sendable {
    /// Returns a currently valid token string.
    /// - Throws: Any error that prevents a valid token from being returned.
    func validToken() async throws -> String
}
