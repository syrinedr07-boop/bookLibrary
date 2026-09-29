import Foundation
import Observation

@MainActor @Observable
final class FavoritesViewModel {
    private(set) var books: [Book] = []
    var errorMessage: String?
    private let repository: any FavoritesRepository
    private var didLoad = false

    init(repository: any FavoritesRepository) {
        self.repository = repository
        load()
    }

    func isFavorite(_ book: Book) -> Bool {
        books.contains { $0.id == book.id }
    }

    func toggle(_ book: Book) {
        // Retry a failed read before writing, so existing favorites are preserved.
        if !didLoad { load() }
        guard didLoad else { return }
        var updated = books
        if isFavorite(book) {
            updated.removeAll { $0.id == book.id }
        } else {
            updated.append(book)
        }
        do {
            try repository.save(updated)
            books = updated
            errorMessage = nil
        } catch {
            errorMessage = "Impossible d’enregistrer les favoris. Veuillez réessayer."
        }
    }

    private func load() {
        do {
            books = try repository.load()
            didLoad = true
            errorMessage = nil
        } catch {
            errorMessage = "Impossible de charger les favoris. Veuillez réessayer."
        }
    }
}
