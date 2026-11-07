import Observation

@Observable
@MainActor
final class ChatListViewModel {
    private let api: any VKAPI
    private let realtime: RealtimeService

    private(set) var chats: [ChatSummary] = []
    private(set) var isLoading = false
    private(set) var error: String?

    private var eventTask: Task<Void, Never>?
    private var reloadTask: Task<Void, Never>?
    private var didLoad = false

    init(api: any VKAPI, realtime: RealtimeService) {
        self.api = api
        self.realtime = realtime
    }

    func start() async {
        subscribe()
        if !didLoad {
            await reload()
        }
    }

    func reload() async {
        isLoading = true
        error = nil
        do {
            let response = try await api.conversations(count: 50)
            chats = ChatSummary.make(from: response)
            didLoad = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func clearError() {
        error = nil
    }

    private func subscribe() {
        guard eventTask == nil else { return }
        eventTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.realtime.events() {
                switch event {
                case .newMessage, .readMessages, .unreadCount:
                    self.scheduleReload()
                case .typing:
                    break
                }
            }
        }
    }

    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled, let self else { return }
            await self.reload()
        }
    }
}
