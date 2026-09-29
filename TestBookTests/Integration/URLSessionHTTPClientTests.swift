import Foundation
import Testing
@testable import TestBook

struct URLSessionHTTPClientTests {
    @Test(arguments: [200, 201, 204, 299]) func acceptsSuccessfulStatus(status: Int) async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let data = try await URLSessionHTTPClient(session: session).send(request(String(status)))
        #expect(data == (status == 204 ? Data() : Data("response".utf8)))
    }

    @Test(arguments: [300, 400, 401, 403, 429, 500]) func rejectsUnsuccessfulStatus(status: Int) async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await URLSessionHTTPClient(session: session).send(request(String(status)))
            Issue.record("Expected HTTP failure")
        } catch let error as HTTPError { #expect(error == .statusCode(status)) }
        catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test func rejectsNonHTTPResponse() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await URLSessionHTTPClient(session: session).send(request("non-http"))
            Issue.record("Expected invalid response")
        } catch let error as HTTPError { #expect(error == .invalidResponse) }
        catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test func preservesTransportErrors() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await URLSessionHTTPClient(session: session).send(request("offline"))
            Issue.record("Expected transport error")
        } catch let error as URLError { #expect(error.code == .notConnectedToInternet) }
        catch { Issue.record("Unexpected error: \(error)") }
    }

    private func request(_ path: String) -> URLRequest {
        URLRequest(url: URL(string: "https://example.test/\(path)")!)
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HTTPResponseURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

// Request-driven responses avoid shared mutable state between parallel tests.
private final class HTTPResponseURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        if url.lastPathComponent == "offline" {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let status = Int(url.lastPathComponent)
        let response: URLResponse
        if let status {
            response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        } else {
            response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if status != 204 { client?.urlProtocol(self, didLoad: Data("response".utf8)) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
