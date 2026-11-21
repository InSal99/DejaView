import Foundation
import SwiftData

enum SharedContainer {
    /// Must match the App Groups capability on both targets.
    static let appGroupID = "group.com.H747JY2BA4.dejaview"

    static let container: ModelContainer = {
        let configuration = ModelConfiguration(
            groupContainer: .identifier(appGroupID),
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: SavedPost.self, configurations: configuration)
        } catch {
            #if DEBUG
            fatalError("SharedContainer setup error (check the App Group \(appGroupID) on both targets): \(error)")
            #else
            fatalError("Could not open the shared store: \(error)")
            #endif
        }
    }()
}
