import Foundation

struct GTaskList: Codable, Identifiable {
    var id: String
    var title: String
    var updated: Date?
    var etag: String?
}

struct GTask: Codable, Identifiable {
    var id: String
    var title: String?
    var notes: String?
    var due: Date?
    var status: String?      // needsAction | completed
    var parent: String?
    var position: String?
    var updated: Date?
    var deleted: Bool?
    var etag: String?
}

final class GoogleTasksAPI {
    static let shared = GoogleTasksAPI()
    private let base = URL(string: "https://www.googleapis.com/tasks/v1")!

    // TODO: Fill in real network calls using URLSession + OAuth access token.
    func listTaskLists(updatedMin: Date? = nil, pageToken: String? = nil, token: String) async throws -> ([GTaskList], String?) {
        return ([], nil)
    }

    func listTasks(listId: String, updatedMin: Date? = nil, pageToken: String? = nil, token: String) async throws -> ([GTask], String?) {
        return ([], nil)
    }

    func insertTask(listId: String, task: GTask, token: String) async throws -> GTask { return task }
    func patchTask(listId: String, taskId: String, task: GTask, token: String, ifMatch: String?) async throws -> GTask { return task }
    func moveTask(listId: String, taskId: String, parent: String?, previous: String?, token: String) async throws -> GTask { return GTask(id: taskId) }
    func deleteTask(listId: String, taskId: String, token: String) async throws { }
}