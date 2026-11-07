import SwiftUI

struct TypingIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("печатает")
            ProgressView()
                .controlSize(.mini)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
