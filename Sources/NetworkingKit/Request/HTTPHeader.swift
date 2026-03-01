/// A type-safe HTTP header name.
public struct HTTPHeader: Hashable, Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }

    // MARK: - Common header names

    public static let accept          = HTTPHeader("Accept")
    public static let authorization   = HTTPHeader("Authorization")
    public static let contentType     = HTTPHeader("Content-Type")
    public static let contentLength   = HTTPHeader("Content-Length")
    public static let userAgent       = HTTPHeader("User-Agent")
    public static let acceptLanguage  = HTTPHeader("Accept-Language")
    public static let cacheControl    = HTTPHeader("Cache-Control")
}

// MARK: - Common header values

public extension HTTPHeader {
    enum ContentType {
        public static let json           = "application/json"
        public static let formURLEncoded = "application/x-www-form-urlencoded"
        public static let multipart      = "multipart/form-data"
    }

    enum Accept {
        public static let json = "application/json"
    }
}
