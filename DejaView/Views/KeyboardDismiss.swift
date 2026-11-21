import SwiftUI
import UIKit

extension View {
    /// Hides the keyboard when the user taps outside a text field, or drags the content.
    /// Uses a simultaneous gesture so buttons and links still work.
    func dismissKeyboardOnTap() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            })
    }
}
