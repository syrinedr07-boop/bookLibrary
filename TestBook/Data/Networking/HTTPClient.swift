import Foundation

protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> Data
}
