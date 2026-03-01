import Foundation

/// Errors that can be thrown by `NetworkingKit`.
public enum NetworkError: Error, Sendable, Equatable {
    /// The request path could not be combined with the base URL.
    case invalidURL
    /// The server returned a 401 Unauthorized response.
    case unauthorized
    /// The server returned an error status code outside the 200–299 range.
    case serverError(statusCode: Int, data: Data)
    /// The response body could not be decoded into the expected type.
    case decodingFailed(Error)
    /// The response contained no data when data was expected.
    case noData
    /// A transport-level or other underlying error.
    case underlying(Error)
}

// MARK: - Equatable

extension NetworkError {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.unauthorized, .unauthorized): return true
        case (.noData, .noData): return true
        case (.serverError(let lCode, let lData), .serverError(let rCode, let rData)):
            return lCode == rCode && lData == rData
        case (.decodingFailed, .decodingFailed): return true
        case (.underlying, .underlying): return true
        default: return false
        }
    }
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .unauthorized:
            return "Unauthorized — check your credentials or token."
        case .serverError(let statusCode, _):
            return "Server returned error with status code \(statusCode)."
        case .decodingFailed(let error):
            return "Response decoding failed: \(error.localizedDescription)"
        case .noData:
            return "The response contained no data."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}
