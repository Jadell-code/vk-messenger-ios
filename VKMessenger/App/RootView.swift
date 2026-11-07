import SwiftUI

@MainActor
struct RootView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Group {
            if env.auth.session != nil {
                MainTabView(env: env)
            } else {
                LoginView()
            }
        }
        .task {
            await env.start()
        }
    }
}
