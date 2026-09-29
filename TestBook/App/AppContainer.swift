import Foundation

enum AppContainer {
    @MainActor static func makeFavoritesViewModel() -> FavoritesViewModel {
        let directory = URL.applicationSupportDirectory.appendingPathComponent("TestBook", isDirectory: true)
        return FavoritesViewModel(repository: LocalFavoritesRepository(
            fileURL: directory.appendingPathComponent("favorites.json")
        ))
    }

    @MainActor static func makeBooksViewModel() -> BooksListViewModel {
        let key = ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"]
            ?? (Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String) ?? ""
        return BooksListViewModel(searchBooks: SearchBooksUseCase(
            repository: GoogleBooksRepository(
                httpClient: URLSessionHTTPClient(session: .shared), apiKey: key
            )
        ))
    }
}
