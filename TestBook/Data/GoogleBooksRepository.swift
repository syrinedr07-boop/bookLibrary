import Foundation

struct GoogleBooksRepository: BooksRepository {
    private let httpClient: any HTTPClient
    private let apiKey: String
    private let pageSize = 20

    init(httpClient: any HTTPClient, apiKey: String) {
        self.httpClient = httpClient
        self.apiKey = apiKey
    }

    func makeRequest(query: String, startIndex: Int) throws -> URLRequest {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BooksAPIError.missingAPIKey
        }
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "startIndex", value: String(startIndex)),
            URLQueryItem(name: "maxResults", value: String(pageSize)),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = components.url else { throw BooksAPIError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        return request
    }

    func search(query: String, startIndex: Int) async throws -> BooksPage {
        let request = try makeRequest(query: query, startIndex: startIndex)
        let data: Data
        do {
            data = try await httpClient.send(request)
        } catch HTTPError.invalidResponse {
            throw BooksAPIError.invalidResponse
        } catch HTTPError.statusCode(let status) {
            throw BooksAPIError.http(status)
        }
        let dto: VolumesDTO
        do { dto = try JSONDecoder().decode(VolumesDTO.self, from: data) }
        catch { throw BooksAPIError.invalidResponse }
        let items = dto.items ?? []
        // totalItems is approximate; a short or empty page terminates pagination.
        return BooksPage(books: items.map { $0.book }, nextIndex: items.count == pageSize ? startIndex + items.count : nil)
    }
}
