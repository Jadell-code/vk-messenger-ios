import Foundation
import SwiftUI

struct AvatarView: View {
    let url: URL?
    let initials: String
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(0.15))

            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(Theme.accent)

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        EmptyView()
                    }
                }
                .frame(width: size, height: size)
                .clipped()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
