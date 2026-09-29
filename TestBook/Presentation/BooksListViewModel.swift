import Foundation
import Observation

@MainActor @Observable
final class BooksListViewModel {
    var query = ""
    private(set) var books: [Book] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var nextIndex: Int?
    private let searchBooks: SearchBooksUseCase
    private let debounce: Duration
    private var generation = UUID()

    init(searchBooks: SearchBooksUseCase, debounce: Duration = .milliseconds(350)) {
        self.searchBooks = searchBooks
        self.debounce = debounce
    }

    func search() async {
        let token = UUID()
        generation = token
        books = []
        nextIndex = nil
        errorMessage = nil
        isLoading = true
        defer { if generation == token { isLoading = false } }
        do {
            try await Task.sleep(for: debounce)
            let page = try await searchBooks.execute(query: effectiveQuery)
            try Task.checkCancellation()
            guard generation == token else { return }
            books = unique(page.books)
            nextIndex = page.nextIndex
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoading, let index = nextIndex else { return }
        let token = generation
        isLoading = true
        errorMessage = nil
        defer { if generation == token { isLoading = false } }
        do {
            let page = try await searchBooks.execute(query: effectiveQuery, startIndex: index)
            try Task.checkCancellation()
            guard generation == token else { return }
            books = unique(books + page.books)
            nextIndex = page.nextIndex
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    private var effectiveQuery: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "subject:fiction" : trimmed
    }

    private func unique(_ values: [Book]) -> [Book] {
        var ids = Set<String>()
        return values.filter { ids.insert($0.id).inserted }
    }
}
