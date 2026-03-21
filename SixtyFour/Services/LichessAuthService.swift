import AuthenticationServices
import CryptoKit
import Foundation

final class LichessAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = LichessAuthService()

    private let clientID = "sixtyfour-ios"
    private let redirectURI = "com.markorel.sixtyfour://lichess-callback"
    private let scopes = "puzzle:read"

    func authenticate() async throws -> (username: String, accessToken: String) {
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)

        let authURL = buildAuthURL(challenge: challenge)
        let callbackURL = try await startAuthSession(url: authURL)

        guard let code = extractCode(from: callbackURL) else {
            throw ChessServiceError.authRequired
        }

        let token = try await exchangeCodeForToken(code: code, verifier: verifier)
        let username = try await fetchUsername(token: token)

        return (username: username, accessToken: token)
    }

    // MARK: - PKCE

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(128)
            .description
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Auth Flow

    private func buildAuthURL(challenge: String) -> URL {
        var components = URLComponents(string: "https://lichess.org/oauth")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        return components.url!
    }

    private func startAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "com.markorel.sixtyfour"
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: ChessServiceError.authRequired)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            DispatchQueue.main.async {
                session.start()
            }
        }
    }

    private func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(code: String, verifier: String) async throws -> String {
        let url = URL(string: "https://lichess.org/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(redirectURI)",
            "client_id=\(clientID)",
            "code_verifier=\(verifier)",
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ChessServiceError.authRequired
        }

        let tokenResponse = try JSONDecoder().decode(LichessTokenResponse.self, from: data)
        return tokenResponse.accessToken
    }

    // MARK: - Fetch Username

    private func fetchUsername(token: String) async throws -> String {
        let url = URL(string: "https://lichess.org/api/account")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ChessServiceError.authRequired
        }

        let account = try JSONDecoder().decode(LichessAccountResponse.self, from: data)
        return account.username
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

// MARK: - Response Models

private struct LichessTokenResponse: Codable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

private struct LichessAccountResponse: Codable {
    let id: String
    let username: String
}
