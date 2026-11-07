import Foundation

enum AppConfig {
    static let apiVersion = "5.199"

    static var vkClientID: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "VKClientID") as? String ?? ""
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var isConfigured: Bool {
        guard let clientID = Int(vkClientID) else { return false }
        return clientID > 0
    }

    static var redirectScheme: String {
        "vk\(vkClientID)"
    }

    static var redirectURI: String {
        "\(redirectScheme)://authorize"
    }

    static var authURL: URL? {
        var components = URLComponents(string: "https://oauth.vk.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: vkClientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "display", value: "mobile"),
            URLQueryItem(name: "scope", value: "messages,offline,photos,wall,groups,email"),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "v", value: apiVersion),
            URLQueryItem(name: "revoke", value: "1")
        ]
        return components?.url
    }
}
