import SwiftUI

@MainActor
struct LoginView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.accent, Color(red: 0.04, green: 0.06, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 104, height: 104)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Messenger")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Клиент ВКонтакте для iOS")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        signIn()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(Theme.accent)
                            }
                            Text(isLoading ? "Входим…" : "Войти через VK")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .foregroundStyle(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isLoading || !AppConfig.isConfigured)

                    Button {
                        env.auth.enterDemo()
                    } label: {
                        Text("Посмотреть демо-режим")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .disabled(isLoading)

                    if !AppConfig.isConfigured {
                        Text("Укажи VK_CLIENT_ID в Config/Local.xcconfig, чтобы включить вход через VK.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .alert(
            "Не удалось войти",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func signIn() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                try await env.auth.signInWithVK()
                env.didSignIn()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
