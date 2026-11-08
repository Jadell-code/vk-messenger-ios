import Observation

@Observable
@MainActor
final class AuthStore {
    private(set) var session: VKSession?
    private(set) var isDemo = false

    private let keychain = KeychainStore()
    private let vkID = VKIDClient()
    private var pendingAuth: PendingVKIDAuth?
    private var isRefreshing = false

    private struct PendingVKIDAuth {
        let state: String
        let verifier: String
    }

    init() {
        if let saved = try? keychain.loadSession(),
           !saved.isExpired || saved.refreshToken != nil {
            session = saved
        }
    }

    var isVKID: Bool {
        session?.isVKID == true
    }

    func makeVKIDAuthURL() throws -> URL {
        guard AppConfig.isConfigured else {
            throw AuthError.notConfigured
        }

        let pkce = PKCE()
        let state = PKCE.randomURLSafeString(byteCount: 32)
        pendingAuth = PendingVKIDAuth(state: state, verifier: pkce.verifier)

        guard let url = AppConfig.vkIDAuthURL(state: state, codeChallenge: pkce.challenge) else {
            throw AuthError.failedToStart
        }
        return url
    }

    func completeVKIDSignIn(callbackURL: URL) async throws {
        guard let pending = pendingAuth else {
            throw AuthError.invalidCallback
        }
        pendingAuth = nil

        let callback = try VKIDClient.parseCallback(callbackURL, expectedState: pending.state)
        let newSession = try await vkID.exchange(
            code: callback.code,
            deviceID: callback.deviceID,
            state: pending.state,
            verifier: pending.verifier
        )

        try keychain.saveSession(newSession)
        session = newSession
        isDemo = false
    }

    func cancelVKIDSignIn() {
        pendingAuth = nil
    }

    func refreshSessionIfNeeded() async {
        guard !isDemo,
              !isRefreshing,
              let current = session,
              current.isExpired,
              current.refreshToken != nil
        else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let updated = try await vkID.refresh(current)
            guard session?.accessToken == current.accessToken else { return }
            try keychain.saveSession(updated)
            session = updated
        } catch {
            // Оставляем старую сессию: сетевой сбой не должен разлогинивать.
        }
    }

    func enterDemo() {
        isDemo = true
        session = .demo
    }

    func signOut() {
        pendingAuth = nil
        if !isDemo {
            keychain.deleteSession()
        }
        session = nil
        isDemo = false
    }
}
