import Observation

@Observable
@MainActor
final class ChatViewModel {
    let chat: ChatSummary

    private let api: any VKAPI
    private let realtime: RealtimeService
    private let pageSize = 50

    private(set) var messages: [VKMessage] = []
    private(set) var profiles: [Int: VKProfile] = [:]
    private(set) var isLoading = false
    private(set) var isLoadingOlder = false
    private(set) var isSending = false
    private(set) var isPeerTyping = false
    private(set) var canLoadOlder = true
    private(set) var error: String?

    var draft = ""

    private var eventTask: Task<Void, Never>?
    private var typingResetTask: Task<Void, Never>?

    init(chat: ChatSummary, api: any VKAPI, realtime: RealtimeService) {
        self.chat = chat
        self.api = api
        self.realtime = realtime
    }

    var isGroupChat: Bool {
        chat.peer.type == "chat"
    }

    func senderName(for message: VKMessage) -> String? {
        guard isGroupChat, !message.isOut else { return nil }
        return profiles[message.fromId]?.fullName
    }

    func start() async {
        subscribe()
        await reloadTail()
        await markRead()
    }

    func loadOlder() async {
        guard canLoadOlder, !isLoadingOlder, !isLoading else { return }
        isLoadingOlder = true
        do {
            let response = try await api.history(
                peerId: chat.id,
                offset: messages.count,
                count: pageSize
            )
            if response.items.isEmpty || response.items.count < pageSize {
                canLoadOlder = false
            }
            merge(response)
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingOlder = false
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        isSending = true
        draft = ""
        do {
            try await api.sendMessage(peerId: chat.id, text: text)
            await reloadTail()
        } catch {
            draft = text
            self.error = error.localizedDescription
        }
        isSending = false
    }

    func clearError() {
        error = nil
    }

    func stop() {
        eventTask?.cancel()
        eventTask = nil
        typingResetTask?.cancel()
        typingResetTask = nil
    }

    private func reloadTail() async {
        if messages.isEmpty {
            isLoading = true
        }
        error = nil
        do {
            let response = try await api.history(peerId: chat.id, offset: 0, count: pageSize)
            merge(response)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func merge(_ response: HistoryResponse) {
        var byId = Dictionary(messages.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for message in response.items {
            byId[message.id] = message
        }
        messages = byId.values.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.id < rhs.id
            }
            return lhs.date < rhs.date
        }

        for profile in response.profiles ?? [] {
            profiles[profile.id] = profile
        }
    }

    private func markRead() async {
        do {
            try await api.markAsRead(peerId: chat.id)
        } catch {
            // Отметка о прочтении не критична для работы чата.
        }
    }

    private func subscribe() {
        guard eventTask == nil else { return }
        eventTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.realtime.events() {
                switch event {
                case .newMessage(let peerId, _, _, _, _, _):
                    guard peerId == self.chat.id else { continue }
                    await self.reloadTail()
                    await self.markRead()
                case .typing(let peerId, _):
                    guard peerId == self.chat.id else { continue }
                    self.showTyping()
                case .readMessages(let peerId, _):
                    guard peerId == self.chat.id else { continue }
                    await self.reloadTail()
                case .unreadCount:
                    break
                }
            }
        }
    }

    private func showTyping() {
        isPeerTyping = true
        typingResetTask?.cancel()
        typingResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            self?.isPeerTyping = false
        }
    }
}
