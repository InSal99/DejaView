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

/// List row: 72×72 thumbnail, title, "platform · date", optional tag chips and a "…" menu.
struct PostRowView: View {
    let post: SavedPost
    var showsTags = false
    var onDelete: (() -> Void)?

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
                Text("\(post.platform.displayName) · \(post.savedAt.staticAgo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if showsTags, !post.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(post.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if onDelete != nil || originalURL != nil {
                Menu {
                    if let originalURL {
                        Button("Open original", systemImage: "arrow.up.right.square") { openURL(originalURL) }
                    }
                    if let onDelete {
                        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("More options")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
