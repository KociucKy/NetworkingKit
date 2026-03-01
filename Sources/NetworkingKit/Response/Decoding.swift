import Foundation

public extension HTTPResponse {

    /// Decodes the response body into the given `Decodable` type.
    ///
    /// - Parameters:
    ///   - type: The type to decode into.
    ///   - decoder: The `JSONDecoder` to use. Defaults to a plain `JSONDecoder()`.
    /// - Throws: `NetworkError.decodingFailed` wrapping the underlying decoding error.
    func decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
