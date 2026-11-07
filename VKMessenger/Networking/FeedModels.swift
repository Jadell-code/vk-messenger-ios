import Foundation

struct VKCounter: Decodable, Hashable {
    let count: Int?
}

struct VKFeedItem: Decodable, Identifiable, Hashable {
    let type: String
    let sourceId: Int
    let postId: Int?
    let date: Int
    let text: String?
    let likes: VKCounter?
    let comments: VKCounter?
    let reposts: VKCounter?
    let attachments: [VKAttachment]?

    var id: String {
        "\(sourceId)_\(postId ?? 0)"
    }

    var dateValue: Date {
        Date(timeIntervalSince1970: TimeInterval(date))
    }
}

struct FeedResponse: Decodable {
    let items: [VKFeedItem]
    let profiles: [VKProfile]?
    let groups: [VKGroup]?
    let nextFrom: String?
}
