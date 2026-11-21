import SwiftUI
import UIKit

/// Tint used for every light surface (cards, chips, fields): the system blue at low opacity.
extension Color {
    static var surfaceTint: Color { Color.accentColor.opacity(0.12) }
}

extension View {
    /// Light blue surface. An opaque base keeps it consistent over any background, then the tint goes on top.
    func surface<S: Shape>(in shape: S) -> some View {
        background {
            shape.fill(Color(.systemBackground))
            shape.fill(Color.surfaceTint)
        }
    }
}

/// Row background for Form / List sections: light blue over an opaque base.
struct SurfaceRowBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            Color.surfaceTint
        }
    }
}

extension View {
    /// Plain white form canvas so the light blue rows stand out.
    func surfaceForm() -> some View {
        scrollContentBackground(.hidden).background(Color(.systemBackground))
    }
}

enum SurfaceAppearance {
    /// Segmented pickers use a UIKit track colour; make it light blue too.
    static func apply() {
        UISegmentedControl.appearance().backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
    }
}
