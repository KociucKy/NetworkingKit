# NetworkingKit

A Swift 6 networking package built on Swift Concurrency. Plug it into any iOS or macOS app and get a fully typed HTTP client with auth, retry, pagination, interceptors, and logging out of the box.

## Requirements

| | Minimum |
|---|---|
| Swift | 6.0 |
| iOS | 16.0 |
| macOS | 13.0 |

## Installation

Add the package via Swift Package Manager in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/NetworkingKit.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["NetworkingKit"]
    )
]
```

Or add it in Xcode via **File → Add Package Dependencies**.

---

## Quick Start

```swift
import NetworkingKit

let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!
)

let request = HTTPRequest(method: .get, path: "/users")
    .header(.accept, HTTPHeader.Accept.json)

let response = try await client.send(request)
let users = try response.decode([User].self)
```

---

## Core Concepts

### `HTTPClient`

The central protocol. Depend on it throughout your app so you can swap in `MockHTTPClient` during tests.

```swift
public protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}
```

### `HTTPRequest`

A `Sendable` value type built with a fluent API:

```swift
// GET with query parameters
let request = HTTPRequest(method: .get, path: "/posts")
    .header(.accept, HTTPHeader.Accept.json)
    .queryItem("page", "1")
    .queryItem("limit", "20")

// POST with JSON body
struct CreateUser: Encodable { let name: String }

let request = try HTTPRequest(method: .post, path: "/users")
    .body(encodable: CreateUser(name: "Alice"))
// Content-Type: application/json is set automatically
```

### `HTTPResponse`

```swift
let response = try await client.send(request)

response.statusCode   // Int
response.data         // Data
response.headers      // [String: String]
response.isSuccess    // true for 200–299

// Decode JSON
let user = try response.decode(User.self)

// Use a custom decoder
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let user = try response.decode(User.self, decoder: decoder)
```

---

## Authentication

Implement `AuthTokenProvider` to supply tokens. The client calls `validToken()` before every request, so you can transparently refresh an expired token inside the implementation.

```swift
actor MyTokenProvider: AuthTokenProvider {
    private var token: String
    private let refresher: TokenRefresher

    func validToken() async throws -> String {
        if isExpired { token = try await refresher.refresh() }
        return token
    }
}

let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    authProvider: MyTokenProvider()
)
```

The token is injected as `Authorization: Bearer <token>` on every request automatically.

---

## Interceptors

Interceptors mutate requests before they are sent. They run in registration order.

```swift
struct CorrelationIDInterceptor: RequestInterceptor {
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        request.header(HTTPHeader("X-Correlation-ID"), UUID().uuidString)
    }
}

struct LanguageInterceptor: RequestInterceptor {
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        request.header(.acceptLanguage, Locale.current.language.languageCode?.identifier ?? "en")
    }
}

let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    interceptors: [CorrelationIDInterceptor(), LanguageInterceptor()]
)
```

---

## Retry

Configure automatic retry with `RetryPolicy`:

```swift
// Exponential back-off — 2s, 4s, 8s (default)
let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    retryPolicy: RetryPolicy(maxAttempts: 3, backoff: .exponential())
)

// Constant delay
let policy = RetryPolicy(maxAttempts: 2, backoff: .constant(1.5))

// Custom retryable status codes
let policy = RetryPolicy(
    maxAttempts: 3,
    backoff: .exponential(base: 2, maximumDelay: 30),
    retryableStatusCodes: [429, 503]
)

// Opt out entirely
let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    retryPolicy: .none   // default
)
```

Retries are triggered for `429, 500, 502, 503, 504` by default. A `401` always surfaces immediately as `NetworkError.unauthorized` and is never retried.

---

## Pagination

### Page / offset

```swift
var pagination = PageRequest(page: 1, pageSize: 20)

// Build the request
let request = HTTPRequest(method: .get, path: "/posts")
    .paginated(with: pagination)
// Appends ?page=1&pageSize=20

// Advance to the next page
pagination = pagination.next()
```

Decode the response into `PaginatedResponse<T>`:

```swift
struct Post: Decodable { let id: Int; let title: String }

let response = try await client.send(request)
let page = try response.decode(PaginatedResponse<Post>.self)

print(page.items)        // [Post]
print(page.hasNextPage)  // Bool — derived from totalItems when present
```

### Cursor-based

```swift
var pagination = CursorRequest(limit: 20)  // cursor is nil on first fetch

let request = HTTPRequest(method: .get, path: "/events")
    .paginated(with: pagination)
// First page: ?limit=20
// Subsequent: ?limit=20&cursor=abc123

let response = try await client.send(request)
let page = try response.decode(CursorPaginatedResponse<Event>.self)

if page.hasNextPage, let cursor = page.nextCursor {
    pagination = CursorRequest(cursor: cursor, limit: 20)
}
```

Both `PageRequest` and `CursorRequest` support custom query parameter names for APIs that use non-standard keys:

```swift
PageRequest(page: 1, pageSize: 20, pageKey: "p", pageSizeKey: "per_page")
CursorRequest(cursor: nil, limit: 20, cursorKey: "next_token", limitKey: "count")
```

---

## Logging

`NetworkLogger` uses `OSLog` and is **disabled by default**. Pass a configured instance to enable it:

```swift
// Info level — method, URL, status code, latency
let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    logger: NetworkLogger(level: .info)
)

// Debug level — also logs request/response headers and body
let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    logger: NetworkLogger(level: .debug)
)

// Custom OSLog subsystem and category
let logger = NetworkLogger(
    level: .info,
    subsystem: "com.myapp",
    category: "Networking"
)
```

Logs appear in **Console.app** and Xcode's debug console, filterable by subsystem and category.

---

## Error Handling

All errors are surfaced as `NetworkError`:

```swift
do {
    let response = try await client.send(request)
    let user = try response.decode(User.self)
} catch NetworkError.unauthorized {
    // Redirect to login
} catch NetworkError.serverError(let statusCode, let data) {
    // Inspect the raw error body
} catch NetworkError.decodingFailed(let underlyingError) {
    // Model mismatch
} catch NetworkError.invalidURL {
    // Bad path or base URL
} catch NetworkError.noData {
    // Empty response body
} catch NetworkError.underlying(let error) {
    // URLSession / transport error
}
```

---

## Testing

Inject `MockHTTPClient` in unit tests — no network required.

```swift
import NetworkingKit

final class UserServiceTests: XCTestCase {

    func testFetchUsersSuccess() async throws {
        let mock = MockHTTPClient()

        let users = [User(id: 1, name: "Alice")]
        let data = try JSONEncoder().encode(users)
        mock.stub(
            HTTPRequest(method: .get, path: "/users"),
            with: .success(HTTPResponse(statusCode: 200, data: data))
        )

        let service = UserService(client: mock)
        let result = try await service.fetchUsers()

        XCTAssertEqual(result, users)
        XCTAssertEqual(mock.receivedRequests.count, 1)
    }

    func testFetchUsersUnauthorized() async throws {
        let mock = MockHTTPClient()
        mock.stub(
            HTTPRequest(method: .get, path: "/users"),
            with: .failure(NetworkError.unauthorized)
        )

        let service = UserService(client: mock)
        await XCTAssertThrowsError(try await service.fetchUsers())
    }
}
```

`MockHTTPClient` also supports a catch-all handler for dynamic responses:

```swift
mock.setDefaultHandler { request in
    HTTPResponse(statusCode: 200, data: Data())
}
```

---

## Full Configuration Example

```swift
let client = URLSessionHTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    session: .shared,
    authProvider: MyTokenProvider(),
    interceptors: [
        CorrelationIDInterceptor(),
        LanguageInterceptor()
    ],
    retryPolicy: RetryPolicy(
        maxAttempts: 3,
        backoff: .exponential(base: 2, maximumDelay: 30)
    ),
    logger: NetworkLogger(level: .info)
)
```

---

## License

MIT
