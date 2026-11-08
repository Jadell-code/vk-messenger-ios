import Foundation

final class HybridAPIClient: VKAPI {
    private let profileClient: VKAPIClient
    private let demoClient: DemoAPIClient

    init(
        profileClient: VKAPIClient = VKAPIClient(),
        demoClient: DemoAPIClient = DemoAPIClient()
    ) {
        self.profileClient = profileClient
        self.demoClient = demoClient
    }

    func conversations(count: Int) async throws -> ConversationListResponse {
        try await demoClient.conversations(count: count)
    }

    func history(peerId: Int, offset: Int, count: Int) async throws -> HistoryResponse {
        try await demoClient.history(peerId: peerId, offset: offset, count: count)
    }

    func sendMessage(peerId: Int, text: String) async throws {
        try await demoClient.sendMessage(peerId: peerId, text: text)
    }

    func markAsRead(peerId: Int) async throws {
        try await demoClient.markAsRead(peerId: peerId)
    }

    func newsfeed(count: Int, nextFrom: String?) async throws -> FeedResponse {
        try await demoClient.newsfeed(count: count, nextFrom: nextFrom)
    }

    func profile() async throws -> VKProfile {
        try await profileClient.profile()
    }

    func longPollServer() async throws -> LongPollServer {
        throw VKAPIError.longPollFailed(0)
    }

    func longPollCheck(server: String, key: String, ts: Int) async throws -> LongPollResponse {
        throw VKAPIError.longPollFailed(0)
    }
}
