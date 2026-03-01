/// Parameters for a page/offset-based paginated request.
///
/// Add these as query items on your `HTTPRequest`:
/// ```swift
/// let pagination = PageRequest(page: 2, pageSize: 20)
/// let request = HTTPRequest(method: .get, path: "/users")
///     .queryItem(pagination.pageKey, String(pagination.page))
///     .queryItem(pagination.pageSizeKey, String(pagination.pageSize))
/// ```
public struct PageRequest: Sendable {
    /// The 1-based page number to fetch.
    public var page: Int
    /// The number of items per page.
    public var pageSize: Int
    /// Query parameter name for the page number. Defaults to `"page"`.
    public var pageKey: String
    /// Query parameter name for the page size. Defaults to `"pageSize"`.
    public var pageSizeKey: String

    public init(
        page: Int = 1,
        pageSize: Int = 20,
        pageKey: String = "page",
        pageSizeKey: String = "pageSize"
    ) {
        self.page = page
        self.pageSize = pageSize
        self.pageKey = pageKey
        self.pageSizeKey = pageSizeKey
    }

    /// Returns a copy advanced to the next page.
    public func next() -> PageRequest {
        PageRequest(page: page + 1, pageSize: pageSize, pageKey: pageKey, pageSizeKey: pageSizeKey)
    }
}

// MARK: - HTTPRequest convenience

public extension HTTPRequest {
    /// Returns a copy of the request with page/offset pagination query items appended.
    func paginated(with pagination: PageRequest) -> HTTPRequest {
        self
            .queryItem(pagination.pageKey, String(pagination.page))
            .queryItem(pagination.pageSizeKey, String(pagination.pageSize))
    }
}
