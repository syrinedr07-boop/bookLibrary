import Foundation

struct LocalFavoritesRepository: FavoritesRepository {
    let fileURL: URL

    func load() throws -> [Book] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([Book].self, from: Data(contentsOf: fileURL))
    }

    func save(_ books: [Book]) throws {
        let data = try JSONEncoder().encode(books)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}
