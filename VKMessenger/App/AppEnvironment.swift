import Foundation
import Observation

@Observable
@MainActor
final class AppEnvironment {
    let auth = AuthStore()
    let realtime = RealtimeService()

    private let realAPI = VKAPIClient()
    private let demoAPI = DemoAPIClient()

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
        return realAPI
    }

    func start() async {
        guard auth.session != nil, !auth.isDemo else { return }
        realtime.start(api: realAPI)
    }

    func didSignIn() {
        guard !auth.isDemo else { return }
        realtime.start(api: realAPI)
    }

    func signOut() {
        realtime.stop()
        auth.signOut()
    }
}
