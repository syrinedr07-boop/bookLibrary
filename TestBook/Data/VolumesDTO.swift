import Foundation

struct VolumesDTO: Decodable {
    let items: [VolumeDTO]?
}

struct VolumeDTO: Decodable {
    let id: String
    let volumeInfo: Info

    struct Info: Decodable {
        let title: String?
        let authors: [String]?
        let description: String?
        let publishedDate: String?
        let imageLinks: Images?
        let previewLink: String?
    }

    struct Images: Decodable {
        let thumbnail: String?
        let smallThumbnail: String?
    }

    var book: Book {
        Book(id: id, title: volumeInfo.title ?? "Sans titre", authors: volumeInfo.authors ?? [],
             summary: volumeInfo.description, publishedDate: volumeInfo.publishedDate,
             thumbnailURL: Self.httpsURL(volumeInfo.imageLinks?.thumbnail ?? volumeInfo.imageLinks?.smallThumbnail),
             previewURL: Self.httpsURL(volumeInfo.previewLink))
    }

    private static func httpsURL(_ value: String?) -> URL? {
        guard let value, var parts = URLComponents(string: value),
              let scheme = parts.scheme, ["http", "https"].contains(scheme.lowercased()),
              parts.host != nil else { return nil }
        parts.scheme = "https"
        return parts.url
    }
}
