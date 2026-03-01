/// Parameters for a cursor-based paginated request.
///
/// Add these as query items on your `HTTPRequest`:
/// ```swift
/// let pagination = CursorRequest(cursor: response.nextCursor, limit: 20)
/// let request = HTTPRequest(method: .get, path: "/events")
///     .paginated(with: pagination)
/// ```
public struct CursorRequest: Sendable {
    /// The cursor returned by the previous response, or `nil` for the first page.
    public var cursor: String?
    /// The maximum number of items to return.
    public var limit: Int
    /// Query parameter name for the cursor. Defaults to `"cursor"`.
    public var cursorKey: String
    /// Query parameter name for the limit. Defaults to `"limit"`.
    public var limitKey: String

    public init(
        cursor: String? = nil,
        limit: Int = 20,
        cursorKey: String = "cursor",
        limitKey: String = "limit"
    ) {
        self.cursor = cursor
        self.limit = limit
        self.cursorKey = cursorKey
        self.limitKey = limitKey
    }
}

// MARK: - HTTPRequest convenience

public extension HTTPRequest {
    /// Returns a copy of the request with cursor pagination query items appended.
    /// The cursor item is only added when a non-nil cursor is present.
    func paginated(with pagination: CursorRequest) -> HTTPRequest {
        var request = self.queryItem(pagination.limitKey, String(pagination.limit))
        if let cursor = pagination.cursor {
            request = request.queryItem(pagination.cursorKey, cursor)
        }
        return request
    }
}
