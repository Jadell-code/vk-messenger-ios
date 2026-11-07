import SwiftUI

@MainActor
struct ProfileView: View {
    let viewModel: ProfileViewModel
    let env: AppEnvironment

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
                        Text(env.auth.isDemo ? "Демо" : "VK API")
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
