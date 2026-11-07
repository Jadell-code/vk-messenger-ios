import Foundation

enum RealtimeEvent: Sendable, Equatable {
    case newMessage(peerId: Int, messageId: Int, fromId: Int, date: Int, text: String, isOut: Bool)
    case typing(peerId: Int, userId: Int)
    case readMessages(peerId: Int, messageId: Int)
    case unreadCount(Int)
}

@MainActor
final class RealtimeService {
    private var continuations: [UUID: AsyncStream<RealtimeEvent>.Continuation] = [:]
    private var pollingTask: Task<Void, Never>?

    func events() -> AsyncStream<RealtimeEvent> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.continuations[id] = nil
                }
            }
        }
    }

    func start(api: any VKAPI) {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self, api] in
            guard let self else { return }
            await self.run(api: api)
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }

    private func run(api: any VKAPI) async {
        while !Task.isCancelled {
            do {
                let server = try await api.longPollServer()
                var ts = server.ts

                while !Task.isCancelled {
                    let response = try await api.longPollCheck(server: server.server, key: server.key, ts: ts)
                    if let failed = response.failed {
                        throw VKAPIError.longPollFailed(failed)
                    }
                    if let newTs = response.ts {
                        ts = newTs
                    }
                    for update in response.updates ?? [] {
                        handle(update)
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                if Task.isCancelled {
                    return
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    private func handle(_ update: [JSONValue]) {
        guard let code = update.first?.intValue else { return }

        switch code {
        case 4:
            guard update.count >= 6 else { return }
            let messageId = update[1].intValue ?? 0
            let flags = update[2].intValue ?? 0
            let peerId = update[3].intValue ?? 0
            let timestamp = update[4].intValue ?? 0
            let text = update[5].stringValue ?? ""
            emit(
                .newMessage(
                    peerId: peerId,
                    messageId: messageId,
                    fromId: 0,
                    date: timestamp,
                    text: text,
                    isOut: (flags & 2) != 0
                )
            )

        case 6, 7:
            guard update.count >= 3 else { return }
            let peerId = update[1].intValue ?? 0
            let messageId = update[2].intValue ?? 0
            emit(.readMessages(peerId: peerId, messageId: messageId))

        case 61:
            guard update.count >= 2 else { return }
            let userId = update[1].intValue ?? 0
            emit(.typing(peerId: userId, userId: userId))

        case 62:
            guard update.count >= 3 else { return }
            let userId = update[1].intValue ?? 0
            let chatId = update[2].intValue ?? 0
            emit(.typing(peerId: 2_000_000_000 + chatId, userId: userId))

        case 80:
            guard update.count >= 2, let count = update[1].intValue else { return }
            emit(.unreadCount(count))

        default:
            break
        }
    }

    private func emit(_ event: RealtimeEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }
}
