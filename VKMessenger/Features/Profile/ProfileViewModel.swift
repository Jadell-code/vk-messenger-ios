import Observation

@Observable
@MainActor
final class ProfileViewModel {
    private let api: any VKAPI

    private(set) var profile: VKProfile?
    private(set) var isLoading = false
    private(set) var error: String?

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
            profile = try await api.profile()
            didLoad = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func clearError() {
        error = nil
    }
}
