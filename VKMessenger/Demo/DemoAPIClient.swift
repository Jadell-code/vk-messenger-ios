import Foundation

actor DemoAPIClient: VKAPI {
    private var messagesByPeer = DemoData.messages
    private var nextId = 10_000

    func conversations(count: Int) async throws -> ConversationListResponse {
        try await delay()
        return DemoData.conversations
    }

    func history(peerId: Int, offset: Int, count: Int) async throws -> HistoryResponse {
        try await delay()
        let all = messagesByPeer[peerId] ?? []
        let page = Array(all.dropFirst(offset).prefix(count))
        return HistoryResponse(
            count: all.count,
            items: page,
            profiles: DemoData.profiles,
            groups: DemoData.groups
        )
    }

    func sendMessage(peerId: Int, text: String) async throws {
        try await delay()
        nextId += 1
        let message = VKMessage(
            id: nextId,
            peerId: peerId,
            fromId: DemoData.myId,
            date: Int(Date().timeIntervalSince1970),
            text: text,
            out: 1,
            attachments: nil,
            readState: 0
        )
        messagesByPeer[peerId, default: []].insert(message, at: 0)
    }

    func markAsRead(peerId: Int) async throws {
        try await delay(short: true)
    }

    func newsfeed(count: Int, nextFrom: String?) async throws -> FeedResponse {
        try await delay()
        return DemoData.feed
    }

    func profile() async throws -> VKProfile {
        try await delay()
        return DemoData.profile
    }

    func longPollServer() async throws -> LongPollServer {
        throw VKAPIError.longPollFailed(0)
    }

    func longPollCheck(server: String, key: String, ts: Int) async throws -> LongPollResponse {
        throw VKAPIError.longPollFailed(0)
    }

    private func delay(short: Bool = false) async throws {
        let nanoseconds: UInt64 = short ? 100_000_000 : 300_000_000
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
