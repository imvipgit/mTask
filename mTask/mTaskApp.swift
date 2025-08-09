import SwiftUI

@main
struct mTaskApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var sync = SyncEngine.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(sync)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands { TaskCommands() }
    }
}
