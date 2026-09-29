import Foundation
import Testing
@testable import TestBook

@MainActor
struct FavoritesPersistenceIntegrationTests {
    @Test func firstLaunchDoesNotCreateFileAndSaveCreatesNestedDirectory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("nested/storage/favorites.json")
        let repository = LocalFavoritesRepository(fileURL: url)
        #expect(try repository.load().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: directory.path))

        let books = [makeBook("first"), makeBook("second")]
        try repository.save(books)
        #expect(try LocalFavoritesRepository(fileURL: url).load() == books)
        try repository.save([])
        #expect(try LocalFavoritesRepository(fileURL: url).load().isEmpty)
    }

    @Test func repairedFileCanBeLoadedBeforeNextToggleWithoutLosingFavorites() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("favorites.json")
        let invalidData = Data("not JSON".utf8)
        try invalidData.write(to: url)
        let model = FavoritesViewModel(repository: LocalFavoritesRepository(fileURL: url))
        #expect(model.errorMessage != nil)
        model.toggle(makeBook("new"))
        #expect(try Data(contentsOf: url) == invalidData)

        let restored = makeBook("restored")
        try LocalFavoritesRepository(fileURL: url).save([restored])
        model.toggle(makeBook("new"))
        #expect(model.books == [restored, makeBook("new")])
        #expect(model.errorMessage == nil)
        let recreated = FavoritesViewModel(repository: LocalFavoritesRepository(fileURL: url))
        #expect(recreated.books == model.books)
        #expect(recreated.errorMessage == nil)
    }
}
