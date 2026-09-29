import Foundation
import Testing
@testable import TestBook

@Suite(.serialized)
struct GoogleBooksIntegrationTests {
    @Test @MainActor func completePipelineBuildsRequestAndMapsBooks() async {
        StubURLProtocol.handler = { request in
            let parts = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            let query = Dictionary(uniqueKeysWithValues: parts.queryItems!.map { ($0.name, $0.value ?? "") })
            #expect(parts.scheme == "https")
            #expect(parts.host == "www.googleapis.com")
            #expect(parts.path == "/books/v1/volumes")
            #expect(query["q"] == "L’été & Swift")
            #expect(query["startIndex"] == "0")
            #expect(query["maxResults"] == "20")
            #expect(query["key"] == "test-key")
            #expect(query["printType"] == "books")
            return (200, Data(#"{"items":[{"id":"abc","volumeInfo":{"title":"Swift","authors":["Alice"],"description":"Résumé","publishedDate":"2025","imageLinks":{"thumbnail":"http://books.google.com/cover.jpg"},"previewLink":"https://books.google.com/books?id=abc"}}]}"#.utf8))
        }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let model = BooksListViewModel(searchBooks: SearchBooksUseCase(
            repository: GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: "test-key")), debounce: .zero)
        model.query = "L’été & Swift"
        await model.search()
        #expect(model.books.first?.title == "Swift")
        #expect(model.books.first?.authors == ["Alice"])
        #expect(model.books.first?.summary == "Résumé")
        #expect(model.books.first?.thumbnailURL?.scheme == "https")
        #expect(model.errorMessage == nil)
    }

    @Test func missingOptionalMetadataUsesFallbacks() async throws {
        StubURLProtocol.handler = { _ in (200, Data(#"{"items":[{"id":"1","volumeInfo":{}}]}"#.utf8)) }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let page = try await GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: "test-key").search(query: "swift", startIndex: 0)
        #expect(page.books.first?.title == "Sans titre")
        #expect(page.books.first?.authors == [])
        #expect(page.books.first?.thumbnailURL == nil)
        #expect(page.nextIndex == nil)
    }

    @Test func missingItemsReturnsEmptyPage() async throws {
        StubURLProtocol.handler = { _ in (200, Data(#"{"totalItems":0}"#.utf8)) }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let page = try await GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: "test-key").search(query: "none", startIndex: 0)
        #expect(page.books.isEmpty)
        #expect(page.nextIndex == nil)
    }

    @Test func fullPageAdvancesOffset() async throws {
        let items = (0..<20).map { ["id": String($0), "volumeInfo": ["title": "Book"]] as [String: Any] }
        let data = try JSONSerialization.data(withJSONObject: ["items": items])
        StubURLProtocol.handler = { request in
            #expect(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.contains(URLQueryItem(name: "startIndex", value: "20")) == true)
            return (200, data)
        }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let page = try await GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: "test-key").search(query: "swift", startIndex: 20)
        #expect(page.books.count == 20)
        #expect(page.nextIndex == 40)
    }

    @Test(arguments: [403, 429, 500]) func httpErrorsArePropagated(status: Int) async {
        StubURLProtocol.handler = { _ in (status, Data()) }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: "test-key").search(query: "swift", startIndex: 0)
            Issue.record("Expected HTTP failure")
        } catch BooksAPIError.http(let code) {
            #expect(code == status)
        } catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test func malformedJSONIsRejected() async {
        StubURLProtocol.handler = { _ in (200, Data("invalid".utf8)) }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: "test-key").search(query: "swift", startIndex: 0)
            Issue.record("Expected decoding failure")
        } catch BooksAPIError.invalidResponse {} catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test func networkFailureIsPropagated() async {
        StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: "test-key").search(query: "swift", startIndex: 0)
            Issue.record("Expected network failure")
        } catch let error as URLError { #expect(error.code == .notConnectedToInternet) }
        catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test func missingKeyFailsBeforeSendingRequest() async {
        StubURLProtocol.handler = { _ in
            Issue.record("No request should be sent without a key")
            return (200, Data())
        }
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await GoogleBooksRepository(httpClient: URLSessionHTTPClient(session: session), apiKey: " ").search(query: "swift", startIndex: 0)
            Issue.record("Expected missing key")
        } catch BooksAPIError.missingAPIKey {} catch { Issue.record("Unexpected error: \(error)") }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
