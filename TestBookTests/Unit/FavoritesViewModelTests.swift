import Foundation
import Testing
@testable import TestBook

@MainActor
struct FavoritesViewModelTests {
    @Test func failedLoadIsRetriedBeforeSavingAndPreservesExistingBooks() {
        let existing = makeBook("existing")
        let added = makeBook("added")
        let repository = FavoritesRepositoryDouble(books: [existing])
        repository.loadFails = true
        let model = FavoritesViewModel(repository: repository)
        #expect(model.errorMessage != nil)

        model.toggle(added)
        #expect(repository.savedSnapshots.isEmpty)
        #expect(model.books.isEmpty)

        repository.loadFails = false
        model.toggle(added)
        #expect(model.books == [existing, added])
        #expect(repository.savedSnapshots == [[existing, added]])
        #expect(model.errorMessage == nil)
    }

    @Test func failedSaveCanBeRetriedWithoutLosingExistingSelection() {
        let existing = makeBook("existing")
        let added = makeBook("added")
        let repository = FavoritesRepositoryDouble(books: [existing])
        let model = FavoritesViewModel(repository: repository)
        repository.saveFails = true
        model.toggle(added)
        #expect(model.books == [existing])
        #expect(model.errorMessage != nil)

        repository.saveFails = false
        model.toggle(added)
        #expect(model.books == [existing, added])
        #expect(repository.books == [existing, added])
        #expect(model.errorMessage == nil)
    }

    @Test func favoriteIdentityUsesIDDespiteChangedMetadata() {
        let original = makeBook("same")
        let unrelated = makeBook("other")
        let refreshed = Book(id: "same", title: "Updated title", authors: ["New author"],
                             summary: nil, publishedDate: nil, thumbnailURL: nil, previewURL: nil)
        let repository = FavoritesRepositoryDouble(books: [original, unrelated])
        let model = FavoritesViewModel(repository: repository)
        #expect(model.isFavorite(refreshed))
        model.toggle(refreshed)
        #expect(model.books == [unrelated])
        #expect(repository.books == [unrelated])
        #expect(!model.isFavorite(original))
    }
}

private final class FavoritesRepositoryDouble: FavoritesRepository {
    var books: [Book]
    var loadFails = false
    var saveFails = false
    var savedSnapshots: [[Book]] = []

    init(books: [Book]) { self.books = books }

    func load() throws -> [Book] {
        if loadFails { throw CocoaError(.fileReadUnknown) }
        return books
    }

    func save(_ books: [Book]) throws {
        if saveFails { throw CocoaError(.fileWriteUnknown) }
        self.books = books
        savedSnapshots.append(books)
    }
}
