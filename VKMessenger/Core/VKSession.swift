import Foundation

struct VKSession: Codable, Equatable {
    let accessToken: String
    let userId: Int
    let expiresAt: Date?
    let refreshToken: String?
    let deviceID: String?
    let scope: String?
    let authState: String?

    init(
        accessToken: String,
        userId: Int,
        expiresAt: Date?,
        refreshToken: String? = nil,
        deviceID: String? = nil,
        scope: String? = nil,
        authState: String? = nil
    ) {
        self.accessToken = accessToken
        self.userId = userId
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
        self.deviceID = deviceID
        self.scope = scope
        self.authState = authState
    }

    static let demo = VKSession(accessToken: "demo", userId: 0, expiresAt: nil)

    var isVKID: Bool {
        refreshToken != nil || deviceID != nil
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }

    /// Разбирает ответ старого implicit flow (`#access_token=...`).
    /// Оставлен для совместимости с ранее сохранёнными Standalone-токенами.
    static func parse(callbackURL: URL) throws -> VKSession {
        guard let fragment = callbackURL.fragment, !fragment.isEmpty else {
            throw AuthError.invalidCallback
        }

        var components = URLComponents()
        components.query = fragment
        let items = components.queryItems ?? []
        var values: [String: String] = [:]
        for item in items {
            if let value = item.value {
                values[item.name] = value
            }
        }

        if let error = values["error"] {
            throw AuthError.vk(error: values["error_description"] ?? error)
        }

        guard
            let token = values["access_token"],
            let userIdString = values["user_id"],
            let userId = Int(userIdString)
        else {
            throw AuthError.invalidCallback
        }

        let expiresIn = Int(values["expires_in"] ?? "0") ?? 0
        let expiresAt = expiresIn > 0 ? Date().addingTimeInterval(TimeInterval(expiresIn)) : nil
        return VKSession(accessToken: token, userId: userId, expiresAt: expiresAt)
    }
}

enum AuthError: LocalizedError {
    case notConfigured
    case cancelled
    case failedToStart
    case invalidCallback
    case noRefreshToken
    case vk(error: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Не указан VK_CLIENT_ID. Открой Config/Local.xcconfig и вставь client_id приложения VK ID."
        case .cancelled:
            return "Вход отменён."
        case .failedToStart:
            return "Не удалось открыть страницу авторизации VK ID."
        case .invalidCallback:
            return "VK ID вернул некорректный ответ авторизации."
        case .noRefreshToken:
            return "Сессия VK ID истекла. Войди заново."
        case .vk(let error):
            return "VK ID: \(error)"
        }
    }
}
