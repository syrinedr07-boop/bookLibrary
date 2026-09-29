import Foundation
@testable import TestBook

actor BooksRepositoryStub: BooksRepository {
    private(set) var requests: [(query: String, index: Int)] = []
    var responses: [Result<BooksPage, Error>]

    init(_ responses: [Result<BooksPage, Error>]) { self.responses = responses }

    func search(query: String, startIndex: Int) async throws -> BooksPage {
        requests.append((query, startIndex))
        guard !responses.isEmpty else { throw URLError(.unknown) }
        return try responses.removeFirst().get()
    }
}

func makeBook(_ id: String) -> Book {
    Book(id: id, title: "Livre \(id)", authors: [], summary: nil,
         publishedDate: nil, thumbnailURL: nil, previewURL: nil)
}
