import Foundation

struct Book: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let title: String
    let authors: [String]
    let summary: String?
    let publishedDate: String?
    let thumbnailURL: URL?
    let previewURL: URL?
}
