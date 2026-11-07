import AuthenticationServices
import Observation
import UIKit

@Observable
@MainActor
final class AuthStore {
    private(set) var session: VKSession?
    private(set) var isDemo = false

    private let keychain = KeychainStore()
    private var webAuthSession: ASWebAuthenticationSession?

    init() {
        if let saved = try? keychain.loadSession(), !saved.isExpired {
            session = saved
        }
    }

    func signInWithVK() async throws {
        guard AppConfig.isConfigured, let url = AppConfig.authURL else {
            throw AuthError.notConfigured
        }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let webSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: AppConfig.redirectScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: AuthError.invalidCallback)
                }
            }

            webSession.presentationContextProvider = WebAuthPresentationProvider.shared
            webSession.prefersEphemeralWebBrowserSession = false
            webAuthSession = webSession

            if !webSession.start() {
                continuation.resume(throwing: AuthError.failedToStart)
            }
        }

        let newSession = try VKSession.parse(callbackURL: callbackURL)
        try keychain.saveSession(newSession)
        session = newSession
        isDemo = false
        webAuthSession = nil
    }

    func enterDemo() {
        isDemo = true
        session = .demo
    }

    func signOut() {
        if !isDemo {
            keychain.deleteSession()
        }
        session = nil
        isDemo = false
    }
}

private final class WebAuthPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        return window ?? UIWindow()
    }
}
