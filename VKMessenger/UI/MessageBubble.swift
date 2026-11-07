import SwiftUI

struct MessageBubble: View {
    let message: VKMessage
    let senderName: String?
    let isGroupChat: Bool

    var body: some View {
        HStack {
            if message.isOut {
                Spacer(minLength: 56)
            }

            VStack(alignment: message.isOut ? .trailing : .leading, spacing: 6) {
                if !message.isOut, isGroupChat, let senderName {
                    Text(senderName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }

                if let imageURL = message.attachments?.compactMap({ $0.imageURL }).first {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                                .overlay(ProgressView())
                        }
                    }
                    .frame(width: 220, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(message.isOut ? Color.white : Color.primary)
                } else if let attachment = message.attachments?.first {
                    Text(attachment.previewLabel)
                        .font(.subheadline)
                        .foregroundStyle(message.isOut ? Color.white.opacity(0.9) : Color.secondary)
                }

                HStack(spacing: 4) {
                    Text(Formatters.messageTime(message.dateValue))
                        .font(.caption2)
                        .foregroundStyle(message.isOut ? Color.white.opacity(0.75) : Color.secondary)

                    if message.isOut {
                        Image(systemName: message.readState == 1 ? "checkmark.circle.fill" : "checkmark")
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(message.isOut ? Theme.accent : Theme.incomingBubble)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if !message.isOut {
                Spacer(minLength: 56)
            }
        }
        .padding(.horizontal, 12)
    }
}
