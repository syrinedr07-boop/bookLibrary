protocol BooksRepository: Sendable {
    func search(query: String, startIndex: Int) async throws -> BooksPage
}
