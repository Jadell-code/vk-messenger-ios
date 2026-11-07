import SwiftUI

@MainActor
struct FeedView: View {
    let viewModel: FeedViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts) { post in
                    FeedPostCard(post: post)
                        .onAppear {
                            if post.id == viewModel.posts.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.reload()
        }
        .navigationTitle("Лента")
        .overlay {
            overlayContent
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert(
            "Ошибка",
            isPresented: Binding(
                get: { viewModel.error != nil && !viewModel.posts.isEmpty },
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
        if viewModel.isLoading && viewModel.posts.isEmpty {
            ProgressView("Загружаем ленту…")
        } else if let error = viewModel.error, viewModel.posts.isEmpty {
            ContentUnavailableView {
                Label("Не удалось загрузить", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error)
            } actions: {
                Button("Повторить") {
                    Task { await viewModel.reload() }
                }
            }
        } else if viewModel.posts.isEmpty {
            ContentUnavailableView(
                "Лента пуста",
                systemImage: "newspaper",
                description: Text("Подпишись на сообщества, чтобы видеть новости.")
            )
        }
    }
}

private struct FeedPostCard: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AvatarView(url: post.authorAvatarURL, initials: post.initials, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(Formatters.feedDate(post.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !post.text.isEmpty {
                Text(post.text)
                    .font(.body)
            }

            if let imageURL = post.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .overlay(ProgressView())
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 20) {
                Label("\(post.likes)", systemImage: "heart")
                Label("\(post.comments)", systemImage: "bubble.right")
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
    }
}
