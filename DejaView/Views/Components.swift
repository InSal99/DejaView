import SwiftUI

struct ModelUnavailableBanner: View {
    let reason: String

    var body: some View {
        Label {
            Text("\(reason) Keyword search still works.")
        } icon: {
            Image(systemName: "exclamationmark.triangle")
        }
        .font(.footnote)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CategoryChip: View {
    let category: PostCategory
    var selected = false

    var body: some View {
        Label(category.displayName, systemImage: category.symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? Color.white : category.color)
            .background(selected ? category.color : category.color.opacity(0.15), in: Capsule())
    }
}
