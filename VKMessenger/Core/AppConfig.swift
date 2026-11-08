import Foundation

enum AppConfig {
    static let apiVersion = "5.199"

    static let vkIDAuthorizeURL = "https://id.vk.ru/authorize"
    static let vkIDRedirectURI = "http://localhost"
    static let vkIDScope = "vkid.personal_info"

    static var vkClientID: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "VKClientID") as? String ?? ""
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var isConfigured: Bool {
        guard let clientID = Int(vkClientID) else { return false }
        return clientID > 0
    }

    /// Схема старого Standalone implicit flow. Оставлена для совместимости.
    static var redirectScheme: String {
        "vk\(vkClientID)"
    }

    static var redirectURI: String {
        "\(redirectScheme)://authorize"
    }

    static func vkIDAuthURL(state: String, codeChallenge: String) -> URL? {
        var components = URLComponents(string: vkIDAuthorizeURL)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: vkClientID),
            URLQueryItem(name: "redirect_uri", value: vkIDRedirectURI),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "scope", value: vkIDScope),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components?.url
    }
}
