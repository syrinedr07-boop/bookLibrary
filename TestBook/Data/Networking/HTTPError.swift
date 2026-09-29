enum HTTPError: Error, Equatable {
    case invalidResponse
    case statusCode(Int)
}
