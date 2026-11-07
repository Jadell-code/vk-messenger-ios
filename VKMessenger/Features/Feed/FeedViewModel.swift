import Observation

@Observable
@MainActor
final class FeedViewModel {
    private let api: any VKAPI

    private(set) var posts: [FeedPost] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: String?

    private var nextFrom: String?
    private var didLoad = false

    init(api: any VKAPI) {
        self.api = api
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        await reload()
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let response = try await api.newsfeed(count: 20, nextFrom: nil)
            posts = makePosts(from: response)
            nextFrom = response.nextFrom
            didLoad = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard let nextFrom, !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let response = try await api.newsfeed(count: 20, nextFrom: nextFrom)
            let existing = Set(posts.map(\.id))
            posts.append(contentsOf: makePosts(from: response).filter { !existing.contains($0.id) })
            self.nextFrom = response.nextFrom
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingMore = false
    }

    func clearError() {
        error = nil
    }

    private func makePosts(from response: FeedResponse) -> [FeedPost] {
        let profiles = Dictionary(
            (response.profiles ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let groups = Dictionary(
            (response.groups ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return response.items.compactMap { item in
            FeedPost.make(from: item, profiles: profiles, groups: groups)
        }
    }
}
