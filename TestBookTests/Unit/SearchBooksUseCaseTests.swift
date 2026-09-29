import Testing
@testable import TestBook

struct SearchBooksUseCaseTests {
    @Test func blankQueryDoesNotCallRepository() async throws {
        let repository = BooksRepositoryStub([])
        let page = try await SearchBooksUseCase(repository: repository).execute(query: "  \n ")
        #expect(page.books.isEmpty)
        #expect(page.nextIndex == nil)
        #expect(await repository.requests.isEmpty)
    }

    @Test func trimsQueryAndForwardsPageIndex() async throws {
        let repository = BooksRepositoryStub([.success(BooksPage(books: [makeBook("1")], nextIndex: nil))])
        let page = try await SearchBooksUseCase(repository: repository).execute(query: "  Swift  ", startIndex: 20)
        let requests = await repository.requests
        #expect(requests.count == 1)
        #expect(requests.first?.query == "Swift")
        #expect(requests.first?.index == 20)
        #expect(page.books.map(\.id) == ["1"])
    }
}
