import SwiftUI

/// Bottom sheet to add or edit the user's note on a post.
struct NoteSheet: View {
    @Binding var note: String
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Add a note…", text: $draft, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($focused)
                } footer: {
                    Text("Notes are saved on this device and are used when you search.")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(note.isEmpty ? "Add note" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines) == note)
                }
            }
            .onAppear {
                draft = note
                focused = true
            }
        }
        .presentationDetents([.medium])
    }
}
