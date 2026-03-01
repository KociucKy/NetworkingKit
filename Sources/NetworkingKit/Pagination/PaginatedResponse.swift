// MARK: - Page-based paginated response

/// A decoded response for a page/offset-based paginated endpoint.
///
/// Your API response model should conform to this — or you can decode
/// into a server-specific type and map it to `PaginatedResponse` manually.
public struct PaginatedResponse<Item: Sendable & Decodable>: Sendable, Decodable {
    /// The items returned on this page.
    public let items: [Item]
    /// The current page number.
    public let page: Int
    /// The number of items per page.
    public let pageSize: Int
    /// The total number of items across all pages, if provided by the server.
    public let totalItems: Int?

    /// Returns `true` if there are more pages to fetch.
    public var hasNextPage: Bool {
        guard let total = totalItems else { return !items.isEmpty }
        return page * pageSize < total
    }

    public init(items: [Item], page: Int, pageSize: Int, totalItems: Int? = nil) {
        self.items = items
        self.page = page
        self.pageSize = pageSize
        self.totalItems = totalItems
    }
}

// MARK: - Cursor-based paginated response

/// A decoded response for a cursor-based paginated endpoint.
public struct CursorPaginatedResponse<Item: Sendable & Decodable>: Sendable, Decodable {
    /// The items returned in this page.
    public let items: [Item]
    /// The cursor to pass in the next request, or `nil` if this is the last page.
    public let nextCursor: String?

    /// Returns `true` if there is another page of results.
    public var hasNextPage: Bool { nextCursor != nil }

    public init(items: [Item], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
