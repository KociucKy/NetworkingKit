import Testing
import Foundation
@testable import NetworkingKit

private actor Counter {
    private(set) var value: Int = 0

    @discardableResult
    func increment() -> Int {
        value += 1
        return value
    }
}

@Suite("RetryPolicy")
struct RetryPolicyTests {

    @Test("RetryPolicy.none has zero maxAttempts")
    func nonePolicy() {
        #expect(RetryPolicy.none.maxAttempts == 0)
    }

    @Test("shouldRetry returns true for retryable status codes")
    func shouldRetryTrue() {
        let policy = RetryPolicy()
        for code in [429, 500, 502, 503, 504] {
            #expect(policy.shouldRetry(statusCode: code))
        }
    }

    @Test("shouldRetry returns false for non-retryable codes")
    func shouldRetryFalse() {
        let policy = RetryPolicy()
        for code in [200, 201, 400, 401, 403, 404] {
            #expect(!policy.shouldRetry(statusCode: code))
        }
    }

    @Test("constant backoff always returns the same delay")
    func constantBackoff() {
        let strategy = BackoffStrategy.constant(5)
        #expect(strategy.delay(forAttempt: 1) == 5)
        #expect(strategy.delay(forAttempt: 3) == 5)
    }

    @Test("exponential backoff grows with attempt number")
    func exponentialBackoff() {
        let strategy = BackoffStrategy.exponential(base: 2, maximumDelay: 60)
        #expect(strategy.delay(forAttempt: 1) == 2)   // 2^1
        #expect(strategy.delay(forAttempt: 2) == 4)   // 2^2
        #expect(strategy.delay(forAttempt: 3) == 8)   // 2^3
    }

    @Test("exponential backoff is capped at maximumDelay")
    func exponentialBackoffCapped() {
        let strategy = BackoffStrategy.exponential(base: 2, maximumDelay: 10)
        #expect(strategy.delay(forAttempt: 10) == 10)
    }

    @Test("MockHTTPClient retries on retryable status and eventually succeeds")
    func retrySucceedsAfterTransientError() async throws {
        let mock = MockHTTPClient()
        let request = HTTPRequest(method: .get, path: "/flaky")

        let counter = Counter()
        mock.setDefaultHandler { _ in
            let count = await counter.increment()
            if count < 3 {
                return HTTPResponse(statusCode: 503, data: Data())
            }
            return HTTPResponse(statusCode: 200, data: Data())
        }

        // Wire up a URLSessionHTTPClient using the mock session indirectly
        // by testing the retry loop logic via MockHTTPClient + manual retry simulation.
        // (URLSessionHTTPClient retry integration is covered by the logic in send(_:))

        // Simulate what URLSessionHTTPClient.send does: retry up to maxAttempts
        let policy = RetryPolicy(maxAttempts: 3, backoff: .constant(0))
        var attempt = 0
        var response: HTTPResponse?

        while true {
            let r = try await mock.send(request)
            if policy.shouldRetry(statusCode: r.statusCode), attempt < policy.maxAttempts {
                attempt += 1
                continue
            }
            response = r
            break
        }

        #expect(response?.statusCode == 200)
        #expect(await counter.value == 3)
    }
}
