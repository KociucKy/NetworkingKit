import Foundation

// MARK: - Backoff strategy

/// Determines how long to wait between retry attempts.
public enum BackoffStrategy: Sendable {
    /// Always wait the same number of seconds between retries.
    case constant(TimeInterval)
    /// Wait `base ^ attempt` seconds (capped at `maximumDelay`).
    case exponential(base: TimeInterval = 2, maximumDelay: TimeInterval = 60)

    func delay(forAttempt attempt: Int) -> TimeInterval {
        switch self {
        case .constant(let interval):
            return interval
        case .exponential(let base, let maximumDelay):
            let delay = pow(base, Double(attempt))
            return min(delay, maximumDelay)
        }
    }
}

// MARK: - RetryPolicy

/// Configures automatic retry behaviour for failed requests.
///
/// Pass a `RetryPolicy` when constructing `URLSessionHTTPClient`:
/// ```swift
/// let client = URLSessionHTTPClient(
///     baseURL: URL(string: "https://api.example.com")!,
///     retryPolicy: RetryPolicy(maxAttempts: 3, backoff: .exponential())
/// )
/// ```
public struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts (not counting the initial request).
    /// Defaults to `3`.
    public var maxAttempts: Int
    /// Delay strategy between attempts. Defaults to `.exponential(base: 2)`.
    public var backoff: BackoffStrategy
    /// HTTP status codes that should trigger a retry. Defaults to `[429, 500, 502, 503, 504]`.
    public var retryableStatusCodes: Set<Int>

    public init(
        maxAttempts: Int = 3,
        backoff: BackoffStrategy = .exponential(),
        retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]
    ) {
        self.maxAttempts = maxAttempts
        self.backoff = backoff
        self.retryableStatusCodes = retryableStatusCodes
    }

    /// A policy that performs no retries.
    public static let none = RetryPolicy(maxAttempts: 0)

    // MARK: - Internal helpers

    func shouldRetry(statusCode: Int) -> Bool {
        retryableStatusCodes.contains(statusCode)
    }

    func sleepDuration(forAttempt attempt: Int) -> UInt64 {
        let seconds = backoff.delay(forAttempt: attempt)
        return UInt64(seconds * 1_000_000_000)
    }
}
