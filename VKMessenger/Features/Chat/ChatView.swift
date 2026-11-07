import SwiftUI

@MainActor
struct ChatView: View {
    let chat: ChatSummary
    let env: AppEnvironment

    @State private var viewModel: ChatViewModel

    init(chat: ChatSummary, env: AppEnvironment) {
        self.chat = chat
        self.env = env
        _viewModel = State(
            initialValue: ChatViewModel(chat: chat, api: env.api, realtime: env.realtime)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.canLoadOlder {
                            Button {
                                Task { await viewModel.loadOlder() }
                            } label: {
                                if viewModel.isLoadingOlder {
                                    ProgressView()
                                } else {
                                    Text("Загрузить ещё")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                senderName: viewModel.senderName(for: message),
                                isGroupChat: viewModel.isGroupChat
                            )
                            .id(message.id)
                        }

                        if viewModel.isPeerTyping {
                            TypingIndicator()
                        }
                    }
                    .padding(.vertical, 8)
                }
                .defaultScrollAnchor(.bottom)
                .onChange(of: viewModel.messages.last?.id) { _, _ in
                    scrollToBottom(proxy)
                }
                .overlay {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView("Загружаем сообщения…")
                    }
                }
            }

            inputBar
        }
        .navigationTitle(chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .alert(
            "Ошибка",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private var inputBar: some View {
        @Bindable var viewModel = viewModel

        return HStack(alignment: .bottom, spacing: 10) {
            TextField("Сообщение", text: $viewModel.draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Theme.accent : Color.secondary)
            }
            .disabled(!canSend || viewModel.isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var canSend: Bool {
        !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}
