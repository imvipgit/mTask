import Foundation

struct AppSnapshot: Codable {
    var lists: [TaskList]
    var tasks: [TaskItem]
    var selectedListId: String?
}

final class JSONPersistence {
    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let appSupport = try! fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport.appendingPathComponent("TasksForMac", conformingTo: .directory)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("data.json")
    }

    func load() -> AppSnapshot {
        do {
            let data = try Data(contentsOf: fileURL)
            let snap = try JSONDecoder().decode(AppSnapshot.self, from: data)
            return snap
        } catch {
            // Seed with a sample list & task
            let initialList = TaskList(title: "My Tasks", position: 0)
            let initialTask = TaskItem(listId: initialList.id, title: "Welcome to Tasks for Mac", notes: "Edit me, add subtasks, set a due date.")
            return AppSnapshot(lists: [initialList], tasks: [initialTask], selectedListId: initialList.id)
        }
    }

    func save(snapshot: AppSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save: \(error)")
        }
    }
}