import Foundation

enum DemoData {
    static let myId = 0
    static let now = Int(Date().timeIntervalSince1970)

    static let anna = VKProfile(
        id: 101,
        firstName: "Анна",
        lastName: "Петрова",
        photo100: "https://i.pravatar.cc/200?img=47",
        photo200: "https://i.pravatar.cc/200?img=47",
        online: 1,
        status: "На связи"
    )

    static let dmitry = VKProfile(
        id: 102,
        firstName: "Дмитрий",
        lastName: "Соколов",
        photo100: "https://i.pravatar.cc/200?img=12",
        photo200: "https://i.pravatar.cc/200?img=12",
        online: 0,
        status: "Работаю"
    )

    static let igor = VKProfile(
        id: 103,
        firstName: "Игорь",
        lastName: "Волков",
        photo100: "https://i.pravatar.cc/200?img=33",
        photo200: "https://i.pravatar.cc/200?img=33",
        online: 1,
        status: nil
    )

    static let demoProfile = VKProfile(
        id: myId,
        firstName: "Демо",
        lastName: "Пользователь",
        photo100: "https://i.pravatar.cc/200?img=5",
        photo200: "https://i.pravatar.cc/200?img=5",
        online: 1,
        status: "Демо-режим без подключения к VK API"
    )

    static let vkTeam = VKGroup(
        id: 555,
        name: "VK Team",
        photo100: "https://i.pravatar.cc/200?img=68",
        photo200: "https://i.pravatar.cc/200?img=68"
    )

    static let profiles = [anna, dmitry, igor, demoProfile]
    static let groups = [vkTeam]

    static var conversations: ConversationListResponse {
        let items = [
            VKConversationItem(
                conversation: VKConversation(
                    peer: VKPeer(id: 101, type: "user", localId: nil),
                    lastMessageId: 3,
                    unreadCount: 2,
                    chatSettings: nil
                ),
                lastMessage: message(
                    id: 3,
                    peerId: 101,
                    fromId: 101,
                    minutesAgo: 3,
                    text: "Тогда до встречи! 👋"
                )
            ),
            VKConversationItem(
                conversation: VKConversation(
                    peer: VKPeer(id: 2_000_000_001, type: "chat", localId: 1),
                    lastMessageId: 203,
                    unreadCount: 0,
                    chatSettings: VKChatSettings(
                        title: "Рабочий чат",
                        photo: nil,
                        membersCount: 8
                    )
                ),
                lastMessage: message(
                    id: 203,
                    peerId: 2_000_000_001,
                    fromId: 103,
                    minutesAgo: 24,
                    text: "Скинул макеты в общий доступ"
                )
            ),
            VKConversationItem(
                conversation: VKConversation(
                    peer: VKPeer(id: 102, type: "user", localId: nil),
                    lastMessageId: 12,
                    unreadCount: 0,
                    chatSettings: nil
                ),
                lastMessage: message(
                    id: 12,
                    peerId: 102,
                    fromId: myId,
                    minutesAgo: 180,
                    text: "Ок, посмотрю вечером",
                    out: 1
                )
            ),
            VKConversationItem(
                conversation: VKConversation(
                    peer: VKPeer(id: 555, type: "group", localId: nil),
                    lastMessageId: 301,
                    unreadCount: 1,
                    chatSettings: nil
                ),
                lastMessage: message(
                    id: 301,
                    peerId: 555,
                    fromId: -555,
                    minutesAgo: 600,
                    text: "Обновление VK API: что нового"
                )
            )
        ]
        return ConversationListResponse(
            count: items.count,
            items: items,
            profiles: profiles,
            groups: groups
        )
    }

    static var messages: [Int: [VKMessage]] {
        [
            101: [
                message(id: 3, peerId: 101, fromId: 101, minutesAgo: 3, text: "Тогда до встречи! 👋", readState: 0),
                message(id: 2, peerId: 101, fromId: myId, minutesAgo: 7, text: "Да, выглядит отлично 👌", out: 1),
                message(id: 1, peerId: 101, fromId: 101, minutesAgo: 12, text: "Привет! Ты уже посмотрел новую ленту?")
            ],
            2_000_000_001: [
                message(id: 203, peerId: 2_000_000_001, fromId: 103, minutesAgo: 24, text: "Скинул макеты в общий доступ"),
                message(id: 202, peerId: 2_000_000_001, fromId: 101, minutesAgo: 31, text: "Спасибо! Посмотрю после обеда"),
                message(
                    id: 201,
                    peerId: 2_000_000_001,
                    fromId: 103,
                    minutesAgo: 40,
                    text: "Вот первый экран",
                    attachments: [photo("https://picsum.photos/seed/vkchat/800/600")]
                ),
                message(id: 200, peerId: 2_000_000_001, fromId: 103, minutesAgo: 55, text: "Коллеги, привет! Начинаем обсуждение нового релиза")
            ],
            102: [
                message(id: 12, peerId: 102, fromId: myId, minutesAgo: 180, text: "Ок, посмотрю вечером", out: 1, readState: 1),
                message(id: 11, peerId: 102, fromId: 102, minutesAgo: 195, text: "Отправил тебе документы на почту"),
                message(id: 10, peerId: 102, fromId: myId, minutesAgo: 210, text: "Привет! Есть минута?", out: 1, readState: 1)
            ],
            555: [
                message(id: 301, peerId: 555, fromId: -555, minutesAgo: 600, text: "Обновление VK API: что нового"),
                message(id: 300, peerId: 555, fromId: -555, minutesAgo: 610, text: "Рассказываем про изменения в методах messages")
            ]
        ]
    }

    static var feed: FeedResponse {
        let items = [
            VKFeedItem(
                type: "post",
                sourceId: -555,
                postId: 10,
                date: now - 3_600,
                text: "Друзья, мы обновили документацию по VK API. В статье — новые поля LongPoll, работа с вложениями и рекомендации по пагинации. Читайте и задавайте вопросы в комментариях.",
                likes: VKCounter(count: 128),
                comments: VKCounter(count: 14),
                reposts: VKCounter(count: 9),
                attachments: [photo("https://picsum.photos/seed/vkfeed/1200/700")]
            ),
            VKFeedItem(
                type: "post",
                sourceId: 101,
                postId: 11,
                date: now - 7_200,
                text: "Собрала подборку классных мест для осенних прогулок. Сохраняйте, пока не похолодало 🍁",
                likes: VKCounter(count: 46),
                comments: VKCounter(count: 5),
                reposts: VKCounter(count: 2),
                attachments: [photo("https://picsum.photos/seed/vkfeed2/1200/800")]
            ),
            VKFeedItem(
                type: "post",
                sourceId: -555,
                postId: 12,
                date: now - 86_400,
                text: "Как ускорить загрузку истории сообщений: кэширование, инкрементальная подгрузка и оптимизация списков. Разбираем на примере мобильного клиента.",
                likes: VKCounter(count: 87),
                comments: VKCounter(count: 21),
                reposts: VKCounter(count: 12),
                attachments: nil
            )
        ]
        return FeedResponse(items: items, profiles: profiles, groups: groups, nextFrom: nil)
    }

    static var profile: VKProfile {
        demoProfile
    }

    private static func message(
        id: Int,
        peerId: Int,
        fromId: Int,
        minutesAgo: Int,
        text: String,
        out: Int = 0,
        attachments: [VKAttachment]? = nil,
        readState: Int = 1
    ) -> VKMessage {
        VKMessage(
            id: id,
            peerId: peerId,
            fromId: fromId,
            date: now - minutesAgo * 60,
            text: text,
            out: out,
            attachments: attachments,
            readState: readState
        )
    }

    private static func photo(_ url: String) -> VKAttachment {
        VKAttachment(
            type: "photo",
            photo: VKPhoto(
                sizes: [VKPhotoSize(url: url, width: 800, height: 600, type: "x")],
                text: nil
            ),
            video: nil,
            audio: nil,
            doc: nil,
            link: nil,
            sticker: nil
        )
    }
}
