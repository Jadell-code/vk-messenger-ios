import Foundation

struct VKIDClient {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    static func parseCallback(
        _ url: URL,
        expectedState: String
    ) throws -> (code: String, deviceID: String) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw AuthError.invalidCallback
        }

        var values: [String: String] = [:]
        for item in components.queryItems ?? [] {
            values[item.name] = item.value
        }

        if let error = values["error"] {
            throw AuthError.vk(error: values["error_description"] ?? error)
        }

        guard
            let code = values["code"], !code.isEmpty,
            let state = values["state"], state == expectedState,
            let deviceID = values["device_id"], !deviceID.isEmpty
        else {
            throw AuthError.invalidCallback
        }

        return (code, deviceID)
    }

    func exchange(
        code: String,
        deviceID: String,
        state: String,
        verifier: String
    ) async throws -> VKSession {
        let response: TokenResponse = try await post([
            "grant_type": "authorization_code",
            "code": code,
            "code_verifier": verifier,
            "redirect_uri": AppConfig.vkIDRedirectURI,
            "client_id": AppConfig.vkClientID,
            "device_id": deviceID,
            "state": state
        ])

        guard let userId = response.userId else {
            throw VKAPIError.invalidResponse
        }

        return VKSession(
            accessToken: response.accessToken,
            userId: userId,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn ?? 3600)),
            refreshToken: response.refreshToken,
            deviceID: deviceID,
            scope: response.scope,
            authState: state
        )
    }

    func refresh(_ session: VKSession) async throws -> VKSession {
        guard
            let refreshToken = session.refreshToken,
            let deviceID = session.deviceID,
            let state = session.authState
        else {
            throw AuthError.noRefreshToken
        }

        let response: TokenResponse = try await post([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": AppConfig.vkClientID,
            "device_id": deviceID,
            "state": state
        ])

        return VKSession(
            accessToken: response.accessToken,
            userId: response.userId ?? session.userId,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn ?? 3600)),
            refreshToken: response.refreshToken ?? refreshToken,
            deviceID: deviceID,
            scope: response.scope ?? session.scope,
            authState: state
        )
    }

    private func post(_ params: [String: String]) async throws -> TokenResponse {
        guard let url = URL(string: "https://id.vk.ru/oauth2/auth") else {
            throw VKAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = Self.formBody(params).data(using: .utf8)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VKAPIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard (200..<300).contains(http.statusCode) else {
            if let payload = try? decoder.decode(TokenErrorResponse.self, from: data) {
                throw AuthError.vk(error: payload.errorDescription ?? payload.error)
            }
            throw VKAPIError.http(http.statusCode)
        }

        do {
            return try decoder.decode(TokenResponse.self, from: data)
        } catch {
            throw VKAPIError.invalidResponse
        }
    }

    private static func formBody(_ params: [String: String]) -> String {
        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        )

        return params
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
    }
}

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let userId: Int?
    let scope: String?
}

private struct TokenErrorResponse: Decodable {
    let error: String
    let errorDescription: String?
}
