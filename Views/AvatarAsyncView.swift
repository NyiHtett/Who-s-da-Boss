import SwiftUI

struct AvatarAsyncView: View {
    let urlString: String?
    let name: String
    var size: CGFloat = 68

    var body: some View {
        ZStack {
            // Glassy backplate so it looks good while loading
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)

            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        InitialsAvatar(name: name, size: size)
                    @unknown default:
                        InitialsAvatar(name: name, size: size)
                    }
                }
            } else {
                InitialsAvatar(name: name, size: size)
            }
        }
        .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
    }
}

struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 68

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
