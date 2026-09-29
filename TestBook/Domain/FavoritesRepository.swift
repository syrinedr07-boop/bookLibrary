import Foundation

protocol FavoritesRepository {
    func load() throws -> [Book]
    func save(_ books: [Book]) throws
}
