import Foundation

/// The production `HTTPClient` implementation backed by `URLSession`.
///
/// Create one instance per base URL and share it across your app:
/// ```swift
/// let client = URLSessionHTTPClient(
///     baseURL: URL(string: "https://api.example.com")!,
///     authProvider: MyTokenProvider(),
///     interceptors: [CorrelationIDInterceptor()],
///     retryPolicy: RetryPolicy(maxAttempts: 3),
///     logger: NetworkLogger(level: .debug)
/// )
/// ```
public final class URLSessionHTTPClient: HTTPClient {

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let authProvider: (any AuthTokenProvider)?
    private let interceptors: [any RequestInterceptor]
    private let retryPolicy: RetryPolicy
    private let logger: NetworkLogger?

    // MARK: - Initialiser

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        authProvider: (any AuthTokenProvider)? = nil,
        interceptors: [any RequestInterceptor] = [],
        retryPolicy: RetryPolicy = .none,
        logger: NetworkLogger? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authProvider = authProvider
        self.interceptors = interceptors
        self.retryPolicy = retryPolicy
        self.logger = logger
    }

    // MARK: - HTTPClient

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var attempt = 0

        while true {
            do {
                let response = try await performRequest(request)

                if retryPolicy.shouldRetry(statusCode: response.statusCode),
                   attempt < retryPolicy.maxAttempts {
                    attempt += 1
                    try await Task.sleep(nanoseconds: retryPolicy.sleepDuration(forAttempt: attempt))
                    continue
                }

                return response
            } catch {
                if attempt < retryPolicy.maxAttempts {
                    attempt += 1
                    try await Task.sleep(nanoseconds: retryPolicy.sleepDuration(forAttempt: attempt))
                    continue
                }
                throw error
            }
        }
    }

    // MARK: - Private

    private func performRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        // 1. Run interceptors
        var finalRequest = try await interceptors.apply(to: request)

        // 2. Inject auth token
        if let authProvider {
            let token = try await authProvider.validToken()
            finalRequest = finalRequest.header(.authorization, "Bearer \(token)")
        }

        // 3. Build URLRequest
        let urlRequest = try buildURLRequest(from: finalRequest)

        // 4. Log outgoing request
        logger?.logRequest(finalRequest)
        let start = Date()

        // 5. Execute
        let (data, urlResponse) = try await session.data(for: urlRequest)

        let duration = Date().timeIntervalSince(start)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkError.underlying(URLError(.badServerResponse))
        }

        // 6. Map headers
        let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String, let value = pair.value as? String {
                result[key.lowercased()] = value
            }
        }

        let response = HTTPResponse(
            statusCode: httpResponse.statusCode,
            data: data,
            headers: headers
        )

        // 7. Log response
        logger?.logResponse(response, request: finalRequest, duration: duration)

        // 8. Surface auth errors immediately (no retry)
        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        // 9. Surface other server errors
        if !response.isSuccess {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
        }

        return response
    }

    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: true
        ) else {
            throw NetworkError.invalidURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (header, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: header.name)
        }

        return urlRequest
    }
}
