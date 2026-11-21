import SwiftUI
import UIKit

extension Date {
    /// Static text (never counts live): "Today", "Yesterday", "2 weeks ago".
    var staticAgo: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        return formatted(.relative(presentation: .named)).capitalizedFirst
    }

    /// "Saved today", "Saved yesterday", "Saved 2 weeks ago".
    var staticSaved: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Saved today" }
        if calendar.isDateInYesterday(self) { return "Saved yesterday" }
        return "Saved " + formatted(.relative(presentation: .named))
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

/// List row with optional category, tags, and original-link menu.
struct PostRowView: View {
    let post: SavedPost
    var showsTags = false
    var showsCategory = false
    var showsOriginalMenu = true

    @Environment(\.openURL) private var openURL

    private var originalURL: URL? {
        guard let urlString = post.urlString, let url = URL(string: urlString),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PostImage(post: post)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(post.status == .pending ? "Processing…" : post.displayTitle)
                    .font(.headline)
                    .foregroundStyle(post.status == .pending ? .secondary : .primary)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    Label(post.platform.displayName, systemImage: post.platform.symbol)
                    Label(post.savedAt.staticAgo, systemImage: "calendar")
                }
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(.secondary)
                if showsCategory {
                    Label {
                        Text(post.category.displayName).foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: post.category.symbol).foregroundStyle(post.category.color)
                    }
                        .font(.caption.weight(.semibold))
                }
                if showsTags, !post.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(post.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .surface(in: Capsule())
                        }
                    }
                    .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsOriginalMenu, let originalURL {
                Menu {
                    Button("Open original", systemImage: "arrow.up.right.square") { openURL(originalURL) }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("More options")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
