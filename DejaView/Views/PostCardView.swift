import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PostCardView: View {
    let post: SavedPost
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                PostImage(post: post)
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .clipped()
                if post.status == .needsReview {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.yellow, .background)
                        .padding(8)
                }
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(post.status == .pending ? "Processing…" : post.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(post.status == .pending ? .secondary : .primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)
                Text("\(post.platform.displayName) · \(post.savedAt.staticAgo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.bottom, 2)
                CategoryChip(category: post.category)
            }
            .padding([.horizontal, .bottom], 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(post.displayTitle), \(post.category.displayName), \(post.platform.displayName), \(post.savedAt.formatted(date: .abbreviated, time: .omitted))\(post.status == .needsReview ? ", Needs review" : "")")
        .animation(reduceMotion ? nil : .smooth, value: post.statusRaw)
    }
}

struct PostImage: View {
    let post: SavedPost
    var body: some View {
        ZStack {
            Color(.systemBackground)
            post.category.color.opacity(0.15)
            #if canImport(UIKit)
            if let data = post.imageData, let image = UIImage(data: data) {
                GeometryReader { geometry in
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                }
            } else {
                Image(systemName: post.status == .pending ? "sparkles" : post.category.symbol)
                    .font(.largeTitle).foregroundStyle(post.category.color)
            }
            #else
            Image(systemName: post.category.symbol).font(.largeTitle).foregroundStyle(post.category.color)
            #endif
        }
    }
}
