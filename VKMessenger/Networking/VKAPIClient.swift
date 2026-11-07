import Foundation

final class VKAPIClient: VKAPI {
    private let urlSession: URLSession
    private let keychain: KeychainStore

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: configuration)
    }

    // MARK: - Public API

    func conversations(count: Int) async throws -> ConversationListResponse {
        try await call(
            "messages.getConversations",
            params: [
                "count": String(count),
                "extended": "1",
                "fields": "photo_100,photo_200,online,status"
            ]
        )
    }

    func history(peerId: Int, offset: Int, count: Int) async throws -> HistoryResponse {
        try await call(
            "messages.getHistory",
            params: [
                "peer_id": String(peerId),
                "offset": String(offset),
                "count": String(count),
                "extended": "1",
                "fields": "photo_100,photo_200,online,status"
            ]
        )
    }

    func sendMessage(peerId: Int, text: String) async throws {
        _ = try await call(
            "messages.send",
            params: [
                "peer_id": String(peerId),
                "message": text,
                "random_id": String(Int.random(in: 1...Int(Int32.max)))
            ]
        ) as Int
    }

    func markAsRead(peerId: Int) async throws {
        _ = try await call(
            "messages.markAsRead",
            params: ["peer_id": String(peerId)]
        ) as Int
    }

    func newsfeed(count: Int, nextFrom: String?) async throws -> FeedResponse {
        var params: [String: String] = [
            "filters": "post",
            "count": String(count)
        ]
        if let nextFrom {
            params["start_from"] = nextFrom
        }
        return try await call("newsfeed.get", params: params)
    }

    func profile() async throws -> VKProfile {
        guard let session = try keychain.loadSession() else {
            throw VKAPIError.notAuthorized
        }
        let profiles: [VKProfile] = try await call(
            "users.get",
            params: [
                "user_ids": String(session.userId),
                "fields": "photo_100,photo_200,online,status"
            ]
        )
        guard let profile = profiles.first else {
            throw VKAPIError.emptyResponse
        }
        return profile
    }

    func longPollServer() async throws -> LongPollServer {
        try await call(
            "messages.getLongPollServer",
            params: ["lp_version": "3", "need_pts": "0"]
        )
    }

    func longPollCheck(server: String, key: String, ts: Int) async throws -> LongPollResponse {
        let base = server.hasPrefix("http") ? server : "https://\(server)"
        guard var components = URLComponents(string: base) else {
            throw VKAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "act", value: "a_check"),
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "ts", value: String(ts)),
            URLQueryItem(name: "wait", value: "25"),
            URLQueryItem(name: "mode", value: "2"),
            URLQueryItem(name: "version", value: "3")
        ]
        guard let url = components.url else {
            throw VKAPIError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw VKAPIError.invalidResponse
        }
        return try Self.decoder.decode(LongPollResponse.self, from: data)
    }

    // MARK: - Private

    private func call<T: Decodable>(_ method: String, params: [String: String]) async throws -> T {
        guard let session = try keychain.loadSession(), !session.isExpired else {
            throw VKAPIError.notAuthorized
        }

        var allParams = params
        allParams["access_token"] = session.accessToken
        allParams["v"] = AppConfig.apiVersion
        allParams["lang"] = "ru"

        let data = try await perform(method: method, params: allParams)
        let envelope = try Self.decoder.decode(VKEnvelope<T>.self, from: data)

        if let error = envelope.error {
            if error.errorCode == 14 {
                throw VKAPIError.captchaNeeded
            }
            throw VKAPIError.api(code: error.errorCode, message: error.errorMsg)
        }
        guard let response = envelope.response else {
            throw VKAPIError.emptyResponse
        }
        return response
    }

    private func perform(method: String, params: [String: String]) async throws -> Data {
        guard let url = URL(string: "https://api.vk.com/method/\(method)") else {
            throw VKAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formBody(params).data(using: .utf8)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw VKAPIError.invalidResponse
        }
        return data
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
