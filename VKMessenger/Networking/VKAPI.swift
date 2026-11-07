import Foundation

protocol VKAPI {
    func conversations(count: Int) async throws -> ConversationListResponse
    func history(peerId: Int, offset: Int, count: Int) async throws -> HistoryResponse
    func sendMessage(peerId: Int, text: String) async throws
    func markAsRead(peerId: Int) async throws
    func newsfeed(count: Int, nextFrom: String?) async throws -> FeedResponse
    func profile() async throws -> VKProfile
    func longPollServer() async throws -> LongPollServer
    func longPollCheck(server: String, key: String, ts: Int) async throws -> LongPollResponse
}

struct VKEnvelope<T: Decodable>: Decodable {
    let response: T?
    let error: VKAPIErrorPayload?
}

struct VKAPIErrorPayload: Decodable {
    let errorCode: Int
    let errorMsg: String
}

enum VKAPIError: LocalizedError {
    case notAuthorized
    case invalidURL
    case invalidResponse
    case emptyResponse
    case http(Int)
    case api(code: Int, message: String)
    case captchaNeeded
    case longPollFailed(Int)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Сессия VK истекла. Войди заново."
        case .invalidURL:
            return "Некорректный адрес запроса."
        case .invalidResponse:
            return "Сервер вернул некорректный ответ."
        case .emptyResponse:
            return "Пустой ответ сервера."
        case .http(let code):
            return "Ошибка сети (HTTP \(code))."
        case .api(let code, let message):
            switch code {
            case 5:
                return "Сессия VK истекла. Войди заново."
            case 6:
                return "Слишком много запросов. Попробуй позже."
            case 14:
                return "VK требует капчу. API-вход временно ограничен."
            case 15:
                return "Доступ запрещён: \(message)"
            case 100:
                return "Некорректные параметры запроса."
            default:
                return "VK API \(code): \(message)"
            }
        case .captchaNeeded:
            return "VK требует капчу."
        case .longPollFailed(let code):
            return "Ошибка LongPoll (\(code))."
        }
    }

    var isAuthorizationError: Bool {
        switch self {
        case .notAuthorized:
            return true
        case .api(let code, _):
            return code == 5
        default:
            return false
        }
    }
}

// MARK: - LongPoll

struct LongPollServer: Decodable {
    let server: String
    let key: String
    let ts: Int
}

struct LongPollResponse: Decodable {
    let ts: Int?
    let updates: [[JSONValue]]?
    let failed: Int?
}

enum JSONValue: Decodable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Int.self) {
            self = .number(Double(value))
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    var intValue: Int? {
        switch self {
        case .number(let value):
            return Int(value)
        case .string(let value):
            return Int(value)
        default:
            return nil
        }
    }

    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
}
