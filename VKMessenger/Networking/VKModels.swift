import Foundation

// MARK: - Profiles & communities

struct VKProfile: Decodable, Hashable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let photo100: String?
    let photo200: String?
    let online: Int?
    let status: String?

    var fullName: String {
        let value = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        return value.isEmpty ? "Пользователь \(id)" : value
    }

    var avatarURL: URL? {
        (photo200 ?? photo100).flatMap { URL(string: $0) }
    }

    var isOnline: Bool {
        online == 1
    }
}

struct VKGroup: Decodable, Hashable {
    let id: Int
    let name: String?
    let photo100: String?
    let photo200: String?

    var displayName: String {
        name ?? "Сообщество \(id)"
    }

    var avatarURL: URL? {
        (photo200 ?? photo100).flatMap { URL(string: $0) }
    }
}

// MARK: - Conversations

struct VKPeer: Decodable, Hashable {
    let id: Int
    let type: String
    let localId: Int?
}

struct VKChatPhoto: Decodable, Hashable {
    let photo100: String?
    let photo200: String?
}

struct VKChatSettings: Decodable, Hashable {
    let title: String?
    let photo: VKChatPhoto?
    let membersCount: Int?
}

struct VKConversation: Decodable, Hashable {
    let peer: VKPeer
    let lastMessageId: Int?
    let unreadCount: Int?
    let chatSettings: VKChatSettings?
}

struct VKConversationItem: Decodable, Hashable {
    let conversation: VKConversation
    let lastMessage: VKMessage?
}

struct ConversationListResponse: Decodable {
    let count: Int
    let items: [VKConversationItem]
    let profiles: [VKProfile]?
    let groups: [VKGroup]?
}

// MARK: - Messages

struct VKMessage: Decodable, Identifiable, Hashable {
    let id: Int
    let peerId: Int
    let fromId: Int
    let date: Int
    let text: String
    let out: Int
    let attachments: [VKAttachment]?
    let readState: Int?

    var isOut: Bool {
        out == 1
    }

    var dateValue: Date {
        Date(timeIntervalSince1970: TimeInterval(date))
    }

    var previewText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed.replacingOccurrences(of: "\n", with: " ")
        }
        if let attachment = attachments?.first {
            return attachment.previewLabel
        }
        return "Сообщение"
    }
}

struct HistoryResponse: Decodable {
    let count: Int
    let items: [VKMessage]
    let profiles: [VKProfile]?
    let groups: [VKGroup]?
}

// MARK: - Attachments

struct VKPhotoSize: Decodable, Hashable {
    let url: String
    let width: Int?
    let height: Int?
    let type: String
}

struct VKPhoto: Decodable, Hashable {
    let sizes: [VKPhotoSize]?
    let text: String?

    var bestURL: URL? {
        sizes?
            .max { lhs, rhs in
                (lhs.width ?? 0) * (lhs.height ?? 0) < (rhs.width ?? 0) * (rhs.height ?? 0)
            }
            .flatMap { URL(string: $0.url) }
    }
}

struct VKVideo: Decodable, Hashable {
    let title: String?
    let photo130: String?
    let photo320: String?
    let photo800: String?

    var thumbnailURL: URL? {
        (photo800 ?? photo320 ?? photo130).flatMap { URL(string: $0) }
    }
}

struct VKAudio: Decodable, Hashable {
    let artist: String?
    let title: String?
}

struct VKDoc: Decodable, Hashable {
    let title: String?
    let ext: String?
    let url: String?
    let size: Int?
}

struct VKLink: Decodable, Hashable {
    let title: String?
    let url: String?
    let photo: VKPhoto?
}

struct VKStickerImage: Decodable, Hashable {
    let url: String
    let width: Int?
    let height: Int?
}

struct VKSticker: Decodable, Hashable {
    let images: [VKStickerImage]?

    var bestURL: URL? {
        images?.last.flatMap { URL(string: $0.url) }
    }
}

struct VKAttachment: Decodable, Hashable {
    let type: String
    let photo: VKPhoto?
    let video: VKVideo?
    let audio: VKAudio?
    let doc: VKDoc?
    let link: VKLink?
    let sticker: VKSticker?

    var previewLabel: String {
        switch type {
        case "photo":
            return "📷 Фото"
        case "video":
            return "🎬 Видео"
        case "audio":
            return "🎵 Аудио"
        case "doc":
            return "📎 Файл"
        case "sticker":
            return "🙂 Стикер"
        case "gift":
            return "🎁 Подарок"
        default:
            return "[вложение]"
        }
    }

    var imageURL: URL? {
        photo?.bestURL ?? video?.thumbnailURL ?? sticker?.bestURL ?? link?.photo?.bestURL
    }
}
