import Foundation
import Testing
@testable import TestBook

struct GoogleBooksRepositoryTests {
    @Test func decodesDataFromInjectedClient() async throws {
        let client = HTTPClientStub(result: .success(Data(#"{"items":[{"id":"1","volumeInfo":{"title":"Swift"}}]}"#.utf8)))
        let repository = GoogleBooksRepository(httpClient: client, apiKey: "test-key")
        let page = try await repository.search(query: "swift", startIndex: 20)
        #expect(page.books.first?.title == "Swift")
        let request = try #require(await client.requests.first)
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
        #expect(items?.contains(URLQueryItem(name: "startIndex", value: "20")) == true)
    }

    @Test func mapsInvalidHTTPResponseToBooksError() async {
        let client = HTTPClientStub(result: .failure(HTTPError.invalidResponse))
        do {
            _ = try await GoogleBooksRepository(httpClient: client, apiKey: "test-key").search(query: "swift", startIndex: 0)
            Issue.record("Expected invalid response")
        } catch BooksAPIError.invalidResponse {} catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test func preservesCancellation() async {
        let client = HTTPClientStub(result: .failure(CancellationError()))
        do {
            _ = try await GoogleBooksRepository(httpClient: client, apiKey: "test-key").search(query: "swift", startIndex: 0)
            Issue.record("Expected cancellation")
        } catch is CancellationError {} catch { Issue.record("Unexpected error: \(error)") }
    }
}

private actor HTTPClientStub: HTTPClient {
    let result: Result<Data, Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<Data, Error>) { self.result = result }

    func send(_ request: URLRequest) async throws -> Data {
        requests.append(request)
        return try result.get()
    }
}
