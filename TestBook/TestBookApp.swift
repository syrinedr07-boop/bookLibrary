import SwiftUI

@main
struct TestBookApp: App {
    @State private var viewModel = AppContainer.makeBooksViewModel()
    @State private var favorites = AppContainer.makeFavoritesViewModel()

    var body: some Scene {
        WindowGroup { ContentView(viewModel: viewModel, favorites: favorites) }
    }
}
