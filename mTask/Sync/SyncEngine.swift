import Foundation

final class SyncEngine: ObservableObject {
    static let shared = SyncEngine()

    @Published var lastSync: Date? = nil
    private let auth = AuthManager.shared

    // Local-first: currently no network sync. Wire this to GoogleTasksAPI when ready.
    func syncNow() {
        // TODO: Implement merging between local JSON and remote Google Tasks.
        lastSync = Date()
    }
}