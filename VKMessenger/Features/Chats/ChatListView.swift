import SwiftUI

@MainActor
struct ChatListView: View {
    let viewModel: ChatListViewModel
    let env: AppEnvironment

    @State private var searchText = ""

    private var filteredChats: [ChatSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.chats }
        return viewModel.chats.filter { chat in
            chat.title.localizedCaseInsensitiveContains(query)
                || chat.lastMessageText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            if env.isUsingDemoData {
                Section {
                    DemoModeNotice(
                        title: env.auth.isVKID ? "Профиль подключён через VK ID" : "Демо-режим",
                        message: env.auth.isVKID
                            ? "VK не выдаёт новым приложениям доступ к сообщениям, поэтому чаты демонстрационные."
                            : "Чаты и сообщения демонстрационные. Реальный VK API не подключён."
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }

            ForEach(filteredChats) { chat in
                NavigationLink(value: chat) {
                    ChatRow(chat: chat)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Чаты")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Поиск"
        )
        .navigationDestination(for: ChatSummary.self) { chat in
            ChatView(chat: chat, env: env)
        }
        .refreshable {
            await viewModel.reload()
        }
        .overlay {
            overlayContent
        }
        .task {
            await viewModel.start()
        }
        .alert(
            "Ошибка",
            isPresented: Binding(
                get: { viewModel.error != nil && !viewModel.chats.isEmpty },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if viewModel.isLoading && viewModel.chats.isEmpty {
            ProgressView("Загружаем чаты…")
        } else if let error = viewModel.error, viewModel.chats.isEmpty {
            ContentUnavailableView {
                Label("Не удалось загрузить", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error)
            } actions: {
                Button("Повторить") {
                    Task { await viewModel.reload() }
                }
            }
        } else if viewModel.chats.isEmpty {
            ContentUnavailableView(
                "Пока нет чатов",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("Здесь появятся твои диалоги.")
            )
        } else if filteredChats.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }
}

private struct ChatRow: View {
    let chat: ChatSummary

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: chat.avatarURL, initials: chat.initials, size: 52)
                .overlay(alignment: .bottomTrailing) {
                    if chat.isOnline {
                        Circle()
                            .fill(Theme.online)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(chat.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(Formatters.chatTime(chat.lastMessageDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Text(chat.lastMessageText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if chat.unreadCount > 0 {
                        UnreadBadge(count: chat.unreadCount)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
