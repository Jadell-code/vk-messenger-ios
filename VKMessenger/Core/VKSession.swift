import Foundation

struct VKSession: Codable, Equatable {
    let accessToken: String
    let userId: Int
    let expiresAt: Date?

    static let demo = VKSession(accessToken: "demo", userId: 0, expiresAt: nil)

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }

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
    case vk(error: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Не указан VK_CLIENT_ID. Открой Config/Local.xcconfig и вставь client_id приложения VK."
        case .cancelled:
            return "Вход отменён."
        case .failedToStart:
            return "Не удалось открыть страницу авторизации VK."
        case .invalidCallback:
            return "VK вернул некорректный ответ авторизации."
        case .vk(let error):
            return "VK: \(error)"
        }
    }
}
