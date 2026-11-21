import SwiftUI

/// Full-screen image with pinch and double-tap zoom, a close button and a share button.
/// Present it with `.fullScreenCover`.
struct FullImageView: View {
    let imageData: Data
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1

    private var uiImage: UIImage? { UIImage(data: imageData) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            if let uiImage {
                GeometryReader { proxy in
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width * scale, height: proxy.size.height * scale)
                            .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                            .accessibilityLabel("Saved image")
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { scale = min(max(baseScale * $0.magnification, 1), 5) }
                            .onEnded { _ in baseScale = scale }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.snappy) {
                            scale = scale > 1 ? 1 : 2.5
                            baseScale = scale
                        }
                    }
                }
            } else {
                ContentUnavailableView("Can't show this image", systemImage: "photo")
                    .foregroundStyle(.white)
            }

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Close")

                Spacer()

                if let uiImage {
                    ShareLink(item: Image(uiImage: uiImage), preview: SharePreview("Saved image", image: Image(uiImage: uiImage))) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Share")
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .preferredColorScheme(.dark)
    }
}
