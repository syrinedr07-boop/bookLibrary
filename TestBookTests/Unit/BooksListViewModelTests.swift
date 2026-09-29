import Foundation
import Testing
@testable import TestBook

@MainActor
struct BooksListViewModelTests {
    @Test func initialSearchUsesFictionAndEndsLoading() async {
        let repository = BooksRepositoryStub([.success(BooksPage(books: [makeBook("1")], nextIndex: 20))])
        let model = makeModel(repository)
        await model.search()
        #expect(model.books.map(\.id) == ["1"])
        #expect(model.nextIndex == 20)
        #expect(!model.isLoading)
        #expect(model.errorMessage == nil)
        #expect(await repository.requests.first?.query == "subject:fiction")
    }

    @Test func paginationDeduplicatesAndStops() async {
        let repository = BooksRepositoryStub([
            .success(BooksPage(books: [makeBook("1")], nextIndex: 20)),
            .success(BooksPage(books: [makeBook("1"), makeBook("2")], nextIndex: nil))
        ])
        let model = makeModel(repository)
        await model.search()
        await model.loadMore()
        await model.loadMore()
        #expect(model.books.map(\.id) == ["1", "2"])
        #expect(model.nextIndex == nil)
        #expect(await repository.requests.map(\.index) == [0, 20])
    }

    @Test func failedPagePreservesBooksAndCanBeRetried() async {
        let repository = BooksRepositoryStub([
            .success(BooksPage(books: [makeBook("1")], nextIndex: 20)),
            .failure(URLError(.notConnectedToInternet)),
            .success(BooksPage(books: [makeBook("2")], nextIndex: nil))
        ])
        let model = makeModel(repository)
        await model.search()
        await model.loadMore()
        #expect(model.books.map(\.id) == ["1"])
        #expect(model.errorMessage != nil)
        #expect(model.nextIndex == 20)
        #expect(!model.isLoading)
        await model.loadMore()
        #expect(model.books.count == 2)
        #expect(model.errorMessage == nil)
    }

    @Test func newSearchReplacesPreviousResults() async {
        let repository = BooksRepositoryStub([
            .success(BooksPage(books: [makeBook("old")], nextIndex: 20)),
            .success(BooksPage(books: [], nextIndex: nil))
        ])
        let model = makeModel(repository)
        await model.search()
        model.query = "inconnu"
        await model.search()
        #expect(model.books.isEmpty)
        #expect(model.nextIndex == nil)
        #expect(model.errorMessage == nil)
    }

    @Test func initialFailureIsPresented() async {
        let model = makeModel(BooksRepositoryStub([.failure(BooksAPIError.http(429))]))
        await model.search()
        #expect(model.errorMessage == BooksAPIError.http(429).errorDescription)
        #expect(!model.isLoading)
        #expect(model.books.isEmpty)
    }

    @Test func cancelledDebounceDoesNotShowErrorOrCallRepository() async {
        let repository = BooksRepositoryStub([])
        let model = BooksListViewModel(searchBooks: SearchBooksUseCase(repository: repository), debounce: .seconds(60))
        let task = Task { await model.search() }
        task.cancel()
        await task.value
        #expect(model.errorMessage == nil)
        #expect(!model.isLoading)
        #expect(await repository.requests.isEmpty)
    }

    @Test func obsoleteResponseDoesNotReplaceNewSearch() async {
        let repository = SuspendedRepository()
        let model = makeModel(repository)
        model.query = "old"
        let oldTask = Task { await model.search() }
        await repository.waitForOldRequest()
        model.query = "new"
        await model.search()
        await repository.finishOldRequest()
        await oldTask.value
        #expect(model.books.map(\.id) == ["new"])
        #expect(!model.isLoading)
    }

    private func makeModel(_ repository: any BooksRepository) -> BooksListViewModel {
        BooksListViewModel(searchBooks: SearchBooksUseCase(repository: repository), debounce: .zero)
    }
}

private actor SuspendedRepository: BooksRepository {
    private var pending: CheckedContinuation<BooksPage, Never>?
    private var started: CheckedContinuation<Void, Never>?

    func search(query: String, startIndex: Int) async throws -> BooksPage {
        if query == "old" {
            return await withCheckedContinuation { continuation in
                pending = continuation
                started?.resume()
                started = nil
            }
        }
        return BooksPage(books: [makeBook("new")], nextIndex: nil)
    }

    func waitForOldRequest() async {
        if pending != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func finishOldRequest() {
        pending?.resume(returning: BooksPage(books: [makeBook("old")], nextIndex: 20))
        pending = nil
    }
}
