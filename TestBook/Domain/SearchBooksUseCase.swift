import Foundation

struct SearchBooksUseCase: Sendable {
    let repository: any BooksRepository

    func execute(query: String, startIndex: Int = 0) async throws -> BooksPage {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return BooksPage(books: [], nextIndex: nil) }
        return try await repository.search(query: trimmed, startIndex: startIndex)
    }
}
