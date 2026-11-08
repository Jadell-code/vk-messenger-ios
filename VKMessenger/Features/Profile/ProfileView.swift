import SwiftUI

@MainActor
struct ProfileView: View {
    let viewModel: ProfileViewModel
    let env: AppEnvironment

    private var isVKID: Bool {
        env.auth.session?.isVKID == true
    }

    private var modeTitle: String {
        if env.auth.isDemo {
            return "Демо"
        }
        return isVKID ? "VK ID" : "VK API"
    }

    var body: some View {
        List {
            if let profile = viewModel.profile {
                Section {
                    VStack(spacing: 12) {
                        AvatarView(
                            url: profile.avatarURL,
                            initials: Initials.from(profile.fullName),
                            size: 96
                        )

                        Text(profile.fullName)
                            .font(.title2.bold())

                        if let status = profile.status, !status.isEmpty {
                            Text(status)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        HStack(spacing: 6) {
                            Circle()
                                .fill(profile.isOnline ? Theme.online : Color.secondary)
                                .frame(width: 8, height: 8)
                            Text(profile.isOnline ? "online" : "offline")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Аккаунт") {
                    LabeledContent("ID") {
                        Text(String(profile.id))
                    }
                    LabeledContent("Режим") {
                        Text(modeTitle)
                    }
                }

                if isVKID {
                    Section("Ограничение VK") {
                        Text("Вход и профиль работают через VK ID. Доступ к сообщениям VK новым приложениям не выдаёт, поэтому чаты и лента показаны в демо-режиме.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Загружаем профиль…")
                        Spacer()
                    }
                }
            } else if let error = viewModel.error {
                Section {
                    VStack(spacing: 8) {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Повторить") {
                            Task { await viewModel.reload() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }

            Section {
                Button(role: .destructive) {
                    env.signOut()
                } label: {
                    Text(env.auth.isDemo ? "Выйти из демо-режима" : "Выйти")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Профиль")
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.reload()
        }
    }
}
