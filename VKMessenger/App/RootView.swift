import SwiftUI

@MainActor
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if env.isStarting {
                ProgressView("Загружаем…")
            } else if env.auth.session != nil {
                MainTabView(env: env)
            } else {
                LoginView()
            }
        }
        .task {
            await env.start()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await env.refreshIfNeeded() }
        }
    }
}
