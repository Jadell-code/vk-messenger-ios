import Foundation

struct ChatSummary: Identifiable, Hashable {
    let id: Int
    let title: String
    let avatarURL: URL?
    let lastMessageText: String
    let lastMessageDate: Date?
    let unreadCount: Int
    let isOnline: Bool
    let peer: VKPeer

    var initials: String {
        Initials.from(title)
    }

    static func make(from response: ConversationListResponse) -> [ChatSummary] {
        let profiles = Dictionary(
            (response.profiles ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let groups = Dictionary(
            (response.groups ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return response.items.map { item in
            let peer = item.conversation.peer
            var title = "Диалог"
            var avatarURL: URL?
            var isOnline = false

            switch peer.type {
            case "user":
                if let profile = profiles[peer.id] {
                    title = profile.fullName
                    avatarURL = profile.avatarURL
                    isOnline = profile.isOnline
                }
            case "chat":
                title = item.conversation.chatSettings?.title ?? "Чат"
                if let photo = item.conversation.chatSettings?.photo {
                    avatarURL = (photo.photo200 ?? photo.photo100).flatMap { URL(string: $0) }
                }
            case "group":
                let groupId = peer.id < 0 ? -peer.id : peer.id
                if let group = groups[groupId] {
                    title = group.displayName
                    avatarURL = group.avatarURL
                }
            default:
                break
            }

            return ChatSummary(
                id: peer.id,
                title: title,
                avatarURL: avatarURL,
                lastMessageText: item.lastMessage?.previewText ?? "",
                lastMessageDate: item.lastMessage?.dateValue,
                unreadCount: item.conversation.unreadCount ?? 0,
                isOnline: isOnline,
                peer: peer
            )
        }
    }
}
