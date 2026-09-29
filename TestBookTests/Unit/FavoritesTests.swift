import Foundation
import Testing
@testable import TestBook

@MainActor
struct FavoritesTests {
    @Test func favoritesSurviveRecreationAndRemoval() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("favorites.json")
        let book = Book(id: "1", title: "Favorite", authors: ["Author"], summary: "Summary",
                        publishedDate: "2026", thumbnailURL: URL(string: "https://example.com/cover"),
                        previewURL: URL(string: "https://example.com/book"))
        let first = FavoritesViewModel(repository: LocalFavoritesRepository(fileURL: url))
        #expect(!first.isFavorite(book))
        first.toggle(book)
        #expect(first.isFavorite(book))
        let restored = FavoritesViewModel(repository: LocalFavoritesRepository(fileURL: url))
        #expect(restored.books == [book])
        restored.toggle(book)
        #expect(!restored.isFavorite(book))
        #expect(try LocalFavoritesRepository(fileURL: url).load().isEmpty)
    }

    @Test func failedSavePreservesSelection() {
        let model = FavoritesViewModel(repository: FailingFavoritesRepository())
        model.toggle(makeBook("1"))
        #expect(model.isFavorite(makeBook("1")))
        #expect(model.errorMessage != nil)
        model.toggle(makeBook("2"))
        #expect(!model.isFavorite(makeBook("2")))
    }

    @Test func corruptFileIsNotOverwrittenByToggle() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let corrupt = Data("invalid JSON".utf8)
        try corrupt.write(to: url)
        let model = FavoritesViewModel(repository: LocalFavoritesRepository(fileURL: url))
        model.toggle(makeBook("1"))
        #expect(model.errorMessage != nil)
        #expect(!model.isFavorite(makeBook("1")))
        #expect(try Data(contentsOf: url) == corrupt)
    }
}

private struct FailingFavoritesRepository: FavoritesRepository {
    func load() throws -> [Book] {
        return [makeBook("1")]
    }
    func save(_ books: [Book]) throws { throw CocoaError(.fileWriteUnknown) }
}
