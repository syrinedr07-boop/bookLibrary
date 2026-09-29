import SwiftUI

struct ContentView: View {
    let viewModel: BooksListViewModel
    let favorites: FavoritesViewModel

    var body: some View {
        BooksListView(viewModel: viewModel, favorites: favorites)
    }
}
