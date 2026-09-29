import Foundation

enum BooksAPIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Le service de livres n’est pas encore configuré."
        case .invalidResponse: "La réponse de Google Books est illisible."
        case .http(429): "Le quota Google Books est atteint. Réessayez plus tard."
        case .http(400), .http(401), .http(403): "Google Books a refusé la requête. Vérifiez la clé API et ses restrictions."
        case .http: "Google Books est indisponible. Réessayez plus tard."
        }
    }
}
