import SwiftUI

struct BookDetailView: View {
    let book: Book
    let favorites: FavoritesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BookCover(url: book.thumbnailURL)
                    .frame(height: 220).frame(maxWidth: .infinity)
                Text(book.title).font(.largeTitle.bold())
                Text(book.authors.isEmpty ? "Auteur inconnu" : book.authors.joined(separator: ", "))
                    .font(.title3).foregroundStyle(.secondary)
                if let date = book.publishedDate { Text("Publication : \(date)").font(.subheadline) }
                Text(book.summary ?? "Aucune description disponible.")
                if let url = book.previewURL {
                    Link(destination: url) { Label("Voir sur Google Books", systemImage: "arrow.up.right.square") }
                }
            }.padding()
        }
        .navigationTitle("Le livre")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FavoriteButton(book: book, favorites: favorites)
            }
        }
    }
}
