import Testing
import Foundation
@testable import NetworkingKit

// MARK: - PageRequest tests

@Suite("PageRequest")
struct PageRequestTests {

    @Test("defaults to page 1 with pageSize 20")
    func defaults() {
        let p = PageRequest()
        #expect(p.page == 1)
        #expect(p.pageSize == 20)
    }

    @Test("next() increments page by one")
    func next() {
        let p = PageRequest(page: 3, pageSize: 10)
        let next = p.next()
        #expect(next.page == 4)
        #expect(next.pageSize == 10)
    }

    @Test("paginated(with:) appends correct query items")
    func paginatedQueryItems() {
        let request = HTTPRequest(method: .get, path: "/items")
            .paginated(with: PageRequest(page: 2, pageSize: 15))

        let items = request.queryItems
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
        #expect(items.contains(URLQueryItem(name: "pageSize", value: "15")))
    }

    @Test("custom key names are used")
    func customKeys() {
        let pagination = PageRequest(page: 1, pageSize: 10, pageKey: "p", pageSizeKey: "size")
        let request = HTTPRequest(method: .get, path: "/items")
            .paginated(with: pagination)

        #expect(request.queryItems.contains(URLQueryItem(name: "p", value: "1")))
        #expect(request.queryItems.contains(URLQueryItem(name: "size", value: "10")))
    }
}

// MARK: - CursorRequest tests

@Suite("CursorRequest")
struct CursorRequestTests {

    @Test("first page omits cursor query item")
    func firstPageNoCursor() {
        let request = HTTPRequest(method: .get, path: "/events")
            .paginated(with: CursorRequest(cursor: nil, limit: 25))

        let names = request.queryItems.map(\.name)
        #expect(!names.contains("cursor"))
        #expect(names.contains("limit"))
    }

    @Test("subsequent page includes cursor")
    func subsequentPageHasCursor() {
        let request = HTTPRequest(method: .get, path: "/events")
            .paginated(with: CursorRequest(cursor: "abc123", limit: 25))

        #expect(request.queryItems.contains(URLQueryItem(name: "cursor", value: "abc123")))
        #expect(request.queryItems.contains(URLQueryItem(name: "limit", value: "25")))
    }
}

// MARK: - PaginatedResponse tests

@Suite("PaginatedResponse")
struct PaginatedResponseTests {

    @Test("hasNextPage is true when more items remain")
    func hasNextPageTrue() {
        let response = PaginatedResponse(items: [1, 2], page: 1, pageSize: 2, totalItems: 10)
        #expect(response.hasNextPage)
    }

    @Test("hasNextPage is false on last page")
    func hasNextPageFalse() {
        let response = PaginatedResponse(items: [1, 2], page: 5, pageSize: 2, totalItems: 10)
        #expect(!response.hasNextPage)
    }

    @Test("hasNextPage falls back to items not empty when totalItems is nil")
    func hasNextPageFallback() {
        let withItems = PaginatedResponse<Int>(items: [1], page: 1, pageSize: 10, totalItems: nil)
        let empty = PaginatedResponse<Int>(items: [], page: 1, pageSize: 10, totalItems: nil)
        #expect(withItems.hasNextPage)
        #expect(!empty.hasNextPage)
    }
}

// MARK: - CursorPaginatedResponse tests

@Suite("CursorPaginatedResponse")
struct CursorPaginatedResponseTests {

    @Test("hasNextPage is true when nextCursor is present")
    func hasNextPageTrue() {
        let response = CursorPaginatedResponse(items: [1], nextCursor: "next-token")
        #expect(response.hasNextPage)
    }

    @Test("hasNextPage is false when nextCursor is nil")
    func hasNextPageFalse() {
        let response = CursorPaginatedResponse<Int>(items: [], nextCursor: nil)
        #expect(!response.hasNextPage)
    }
}
