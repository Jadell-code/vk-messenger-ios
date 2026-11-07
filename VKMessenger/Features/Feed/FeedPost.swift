import Foundation

struct FeedPost: Identifiable, Hashable {
    let id: String
    let authorName: String
    let authorAvatarURL: URL?
    let date: Date
    let text: String
    let imageURL: URL?
    let likes: Int
    let comments: Int

    var initials: String {
        Initials.from(authorName)
    }

    static func make(
        from item: VKFeedItem,
        profiles: [Int: VKProfile],
        groups: [Int: VKGroup]
    ) -> FeedPost? {
        guard item.type == "post" else { return nil }

        let authorName: String
        let authorAvatarURL: URL?

        if item.sourceId > 0, let profile = profiles[item.sourceId] {
            authorName = profile.fullName
            authorAvatarURL = profile.avatarURL
        } else if let group = groups[-item.sourceId] {
            authorName = group.displayName
            authorAvatarURL = group.avatarURL
        } else {
            authorName = "ВКонтакте"
            authorAvatarURL = nil
        }

        return FeedPost(
            id: item.id,
            authorName: authorName,
            authorAvatarURL: authorAvatarURL,
            date: item.dateValue,
            text: item.text ?? "",
            imageURL: item.attachments?.compactMap { $0.imageURL }.first,
            likes: item.likes?.count ?? 0,
            comments: item.comments?.count ?? 0
        )
    }
}
