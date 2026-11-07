import SwiftUI

@MainActor
struct MainTabView: View {
    let env: AppEnvironment

    @State private var chatListViewModel: ChatListViewModel
    @State private var feedViewModel: FeedViewModel
    @State private var profileViewModel: ProfileViewModel

    init(env: AppEnvironment) {
        self.env = env
        _chatListViewModel = State(initialValue: ChatListViewModel(api: env.api, realtime: env.realtime))
        _feedViewModel = State(initialValue: FeedViewModel(api: env.api))
        _profileViewModel = State(initialValue: ProfileViewModel(api: env.api))
    }

    var body: some View {
        TabView {
            NavigationStack {
                ChatListView(viewModel: chatListViewModel, env: env)
            }
            .tabItem {
                Label("Чаты", systemImage: "bubble.left.and.bubble.right.fill")
            }

            NavigationStack {
                FeedView(viewModel: feedViewModel)
            }
            .tabItem {
                Label("Лента", systemImage: "newspaper.fill")
            }

            NavigationStack {
                ProfileView(viewModel: profileViewModel, env: env)
            }
            .tabItem {
                Label("Профиль", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(Theme.accent)
    }
}
