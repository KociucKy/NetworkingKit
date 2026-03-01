import Foundation
import OSLog

/// An OSLog-based logger for HTTP requests and responses.
///
/// Disabled by default. Pass a configured instance to `URLSessionHTTPClient`:
/// ```swift
/// let client = URLSessionHTTPClient(
///     baseURL: URL(string: "https://api.example.com")!,
///     logger: NetworkLogger(level: .debug)
/// )
/// ```
public struct NetworkLogger: Sendable {

    // MARK: - Log level

    public enum Level: Int, Sendable, Comparable {
        /// Logs method, URL, status code, and latency only.
        case info
        /// Also logs request/response headers and body.
        case debug

        public static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Properties

    public let level: Level
    private let logger: Logger

    // MARK: - Initialisers

    public init(
        level: Level = .info,
        subsystem: String = "com.networkingkit",
        category: String = "HTTP"
    ) {
        self.level = level
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    // MARK: - Logging

    func logRequest(_ request: HTTPRequest) {
        logger.info("→ \(request.method.rawValue) \(request.path)")
        guard level >= .debug else { return }
        if !request.headers.isEmpty {
            logger.debug("  Request headers: \(formatHeaders(request.headers))")
        }
        if let body = request.body, let text = String(data: body, encoding: .utf8) {
            logger.debug("  Request body: \(text)")
        }
    }

    func logResponse(_ response: HTTPResponse, request: HTTPRequest, duration: TimeInterval) {
        let ms = String(format: "%.1f", duration * 1000)
        logger.info("← \(response.statusCode) \(request.method.rawValue) \(request.path) [\(ms)ms]")
        guard level >= .debug else { return }
        if !response.headers.isEmpty {
            logger.debug("  Response headers: \(formatHeaders(response.headers))")
        }
        if !response.data.isEmpty, let text = String(data: response.data, encoding: .utf8) {
            logger.debug("  Response body: \(text)")
        }
    }

    func logError(_ error: Error, request: HTTPRequest) {
        logger.error("✗ \(request.method.rawValue) \(request.path) — \(error.localizedDescription)")
    }

    // MARK: - Private helpers

    private func formatHeaders(_ headers: [HTTPHeader: String]) -> String {
        headers.map { "\($0.key.name): \($0.value)" }.joined(separator: ", ")
    }

    private func formatHeaders(_ headers: [String: String]) -> String {
        headers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}
