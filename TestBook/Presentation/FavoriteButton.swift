import SwiftUI

struct FavoriteButton: View {
    let book: Book
    @Bindable var favorites: FavoritesViewModel

    var body: some View {
        Button {
            favorites.toggle(book)
        } label: {
            Image(systemName: favorites.isFavorite(book) ? "heart.fill" : "heart")
                .foregroundStyle(favorites.isFavorite(book) ? Color.red : Color.secondary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(favorites.isFavorite(book) ? "Retirer des favoris" : "Ajouter aux favoris")
        .accessibilityValue(book.title)
    }
}
