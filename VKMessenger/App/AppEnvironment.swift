import Foundation
import Observation

@Observable
@MainActor
final class AppEnvironment {
    let auth = AuthStore()
    let realtime = RealtimeService()

    private let realAPI = VKAPIClient()
    private let demoAPI = DemoAPIClient()
    private let hybridAPI = HybridAPIClient()

    init() {
        // Позволяет запускать демо из CI/схемы Xcode:
        // xcrun simctl launch <device> com.example.messenger --demo
        if ProcessInfo.processInfo.arguments.contains("--demo") {
            auth.enterDemo()
        }
    }

    var api: any VKAPI {
        if auth.isDemo {
            return demoAPI
        }
        if auth.isVKID {
            return hybridAPI
        }
        return realAPI
    }

    var profileAPI: any VKAPI {
        if auth.isDemo {
            return demoAPI
        }
        return realAPI
    }

    /// VK ID даёт только профиль, поэтому чаты и лента берутся из демо-данных.
    var isUsingDemoData: Bool {
        auth.isDemo || auth.isVKID
    }

    func start() async {
        guard auth.session != nil, !auth.isDemo else { return }
        await auth.refreshSessionIfNeeded()

        // Для VK ID LongPoll недоступен: нет scope messages.
        guard !auth.isVKID else { return }
        realtime.start(api: realAPI)
    }

    func didSignIn() {
        guard !auth.isDemo, !auth.isVKID else { return }
        realtime.start(api: realAPI)
    }

    func signOut() {
        realtime.stop()
        auth.signOut()
    }
}
