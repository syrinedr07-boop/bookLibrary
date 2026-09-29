import SwiftUI

struct BooksListView: View {
    @State var viewModel: BooksListViewModel
    @Bindable var favorites: FavoritesViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.books) { book in
                        HStack {
                            NavigationLink {
                                BookDetailView(book: book, favorites: favorites)
                            } label: {
                                HStack(alignment: .top, spacing: 16) {
                                    BookCover(url: book.thumbnailURL)
                                        .frame(width: 56, height: 82)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(book.title).font(.headline).lineLimit(3)
                                        Text(book.authors.isEmpty ? "Auteur inconnu" : book.authors.joined(separator: ", "))
                                            .font(.subheadline).foregroundStyle(.secondary)
                                        if let date = book.publishedDate {
                                            Text(date).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            FavoriteButton(book: book, favorites: favorites)
                                .fixedSize()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } header: {
                    Text(viewModel.query.isEmpty ? "À découvrir · Fiction" : "Résultats")
                } footer: {
                    Text("Livres proposés par Google Books")
                }

                if viewModel.isLoading {
                    HStack { Spacer(); ProgressView("Chargement…"); Spacer() }
                } else if let message = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(message).foregroundStyle(.secondary)
                        Button("Réessayer") {
                            Task {
                                if viewModel.books.isEmpty { await viewModel.search() }
                                else { await viewModel.loadMore() }
                            }
                        }
                    }
                } else if viewModel.books.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else if viewModel.nextIndex != nil {
                    Button("Charger plus de livres") { Task { await viewModel.loadMore() } }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Bibliothèque")
            .searchable(text: $viewModel.query, prompt: "Titre, auteur, ISBN")
            .task(id: viewModel.query) { await viewModel.search() }
            .refreshable { await viewModel.search() }
        }
        .alert("Favoris", isPresented: Binding(
            get: { favorites.errorMessage != nil },
            set: { if !$0 { favorites.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { favorites.errorMessage = nil }
        } message: {
            Text(favorites.errorMessage ?? "")
        }
    }
}
