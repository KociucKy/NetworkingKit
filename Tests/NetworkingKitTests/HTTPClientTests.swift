import Testing
import Foundation
@testable import NetworkingKit

// MARK: - Helpers

private struct TestItem: Codable, Equatable {
    let id: Int
    let name: String
}

private func makeJSON(_ items: [TestItem]) throws -> Data {
    try JSONEncoder().encode(items)
}

private func makeJSON(_ item: TestItem) throws -> Data {
    try JSONEncoder().encode(item)
}

// MARK: - MockHTTPClient tests

@Suite("MockHTTPClient")
struct MockHTTPClientTests {

    @Test("records received requests")
    func recordsRequests() async throws {
        let mock = MockHTTPClient()
        let request = HTTPRequest(method: .get, path: "/ping")
        mock.stub(request, with: .success(HTTPResponse(statusCode: 200, data: Data())))

        _ = try await mock.send(request)

        #expect(mock.receivedRequests.count == 1)
        #expect(mock.receivedRequests.first?.path == "/ping")
    }

    @Test("returns stubbed success response")
    func returnsStubbedSuccess() async throws {
        let mock = MockHTTPClient()
        let item = TestItem(id: 1, name: "Alice")
        let data = try makeJSON(item)
        let request = HTTPRequest(method: .get, path: "/users/1")
        mock.stub(request, with: .success(HTTPResponse(statusCode: 200, data: data)))

        let response = try await mock.send(request)
        let decoded = try response.decode(TestItem.self)

        #expect(decoded == item)
    }

    @Test("returns stubbed failure")
    func returnsStubbedFailure() async throws {
        let mock = MockHTTPClient()
        let request = HTTPRequest(method: .get, path: "/fail")
        mock.stub(request, with: .failure(NetworkError.unauthorized))

        await #expect(throws: NetworkError.unauthorized) {
            _ = try await mock.send(request)
        }
    }

    @Test("throws when no stub found")
    func throwsForMissingStub() async throws {
        let mock = MockHTTPClient()
        let request = HTTPRequest(method: .get, path: "/unknown")

        await #expect(throws: (any Error).self) {
            _ = try await mock.send(request)
        }
    }

    @Test("reset clears stubs and history")
    func resetClearsState() async throws {
        let mock = MockHTTPClient()
        let request = HTTPRequest(method: .get, path: "/ping")
        mock.stub(request, with: .success(HTTPResponse(statusCode: 200, data: Data())))
        _ = try await mock.send(request)

        mock.reset()

        #expect(mock.receivedRequests.isEmpty)
    }

    @Test("default handler is invoked for unstubbed requests")
    func defaultHandlerInvoked() async throws {
        let mock = MockHTTPClient()
        mock.setDefaultHandler { _ in
            HTTPResponse(statusCode: 204, data: Data())
        }

        let response = try await mock.send(HTTPRequest(method: .delete, path: "/item/1"))
        #expect(response.statusCode == 204)
    }
}

// MARK: - HTTPRequest builder tests

@Suite("HTTPRequest builder")
struct HTTPRequestBuilderTests {

    @Test("header builder sets value")
    func headerBuilder() {
        let request = HTTPRequest(method: .get, path: "/test")
            .header(.accept, HTTPHeader.Accept.json)

        #expect(request.headers[.accept] == HTTPHeader.Accept.json)
    }

    @Test("queryItem builder appends item")
    func queryItemBuilder() {
        let request = HTTPRequest(method: .get, path: "/search")
            .queryItem("q", "swift")
            .queryItem("page", "1")

        #expect(request.queryItems.count == 2)
        #expect(request.queryItems.first?.name == "q")
    }

    @Test("body builder encodes and sets Content-Type")
    func bodyBuilder() throws {
        let item = TestItem(id: 42, name: "Bob")
        let request = try HTTPRequest(method: .post, path: "/users")
            .body(encodable: item)

        #expect(request.body != nil)
        #expect(request.headers[.contentType] == HTTPHeader.ContentType.json)

        let decoded = try JSONDecoder().decode(TestItem.self, from: request.body!)
        #expect(decoded == item)
    }

    @Test("body builder does not overwrite existing Content-Type")
    func bodyBuilderPreservesContentType() throws {
        let item = TestItem(id: 1, name: "A")
        let request = try HTTPRequest(method: .post, path: "/users")
            .header(.contentType, "application/vnd.api+json")
            .body(encodable: item)

        #expect(request.headers[.contentType] == "application/vnd.api+json")
    }
}

// MARK: - HTTPResponse decoding tests

@Suite("HTTPResponse decoding")
struct HTTPResponseDecodingTests {

    @Test("decodes valid JSON")
    func decodesJSON() throws {
        let item = TestItem(id: 7, name: "Carol")
        let data = try JSONEncoder().encode(item)
        let response = HTTPResponse(statusCode: 200, data: data)

        let decoded = try response.decode(TestItem.self)
        #expect(decoded == item)
    }

    @Test("throws decodingFailed for invalid JSON")
    func throwsDecodingFailed() throws {
        let response = HTTPResponse(statusCode: 200, data: Data("not-json".utf8))

        #expect(throws: NetworkError.self) {
            _ = try response.decode(TestItem.self)
        }
    }

    @Test("isSuccess is true for 2xx")
    func isSuccessTrue() {
        #expect(HTTPResponse(statusCode: 200, data: Data()).isSuccess)
        #expect(HTTPResponse(statusCode: 201, data: Data()).isSuccess)
        #expect(HTTPResponse(statusCode: 299, data: Data()).isSuccess)
    }

    @Test("isSuccess is false for non-2xx")
    func isSuccessFalse() {
        #expect(!HTTPResponse(statusCode: 400, data: Data()).isSuccess)
        #expect(!HTTPResponse(statusCode: 500, data: Data()).isSuccess)
    }
}
