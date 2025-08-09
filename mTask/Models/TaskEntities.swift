import Foundation

// MARK: - Models

struct TaskItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var listId: String                        // which list this task belongs to
    var title: String
    var notes: String = ""
    var due: Date? = nil
    var completed: Bool = false
    var parentId: String? = nil               // for subtasks
    var position: Double = 0                  // ordering within a list
    var updatedAt: Date = Date()
}

struct TaskList: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var position: Double = 0
    var updatedAt: Date = Date()
}

// MARK: - App State

final class AppStore: ObservableObject {
    @Published var lists: [TaskList] = []
    @Published var tasks: [TaskItem] = []
    @Published var selectedListId: String? = nil
    @Published var showCompleted: Bool = false

    private let persistence = JSONPersistence()

    init() {
        load()
        if selectedListId == nil,
           let first = lists.sorted(by: { $0.position < $1.position }).first {
            selectedListId = first.id
        }
    }

    // MARK: - Persistence

    func load() {
        let snapshot = persistence.load()
        self.lists = snapshot.lists
        self.tasks = snapshot.tasks
        self.selectedListId = snapshot.selectedListId
    }

    func save() {
        let snapshot = AppSnapshot(lists: lists, tasks: tasks, selectedListId: selectedListId)
        persistence.save(snapshot: snapshot)
    }

    // MARK: - Lists

    func addList(title: String = "New list") {
        let nextPosition = (lists.map { $0.position }.max() ?? 0) + 1
        let list = TaskList(title: title, position: nextPosition)
        lists.append(list)
        selectedListId = list.id
        save()
    }

    func renameList(id: String, title: String) {
        guard let idx = lists.firstIndex(where: { $0.id == id }) else { return }
        lists[idx].title = title
        lists[idx].updatedAt = Date()
        save()
    }

    func deleteList(id: String) {
        lists.removeAll { $0.id == id }
        tasks.removeAll { $0.listId == id }
        if selectedListId == id { selectedListId = lists.first?.id }
        save()
    }

    func moveList(fromOffsets: IndexSet, toOffset: Int) {
        var ordered = lists.sorted(by: { $0.position < $1.position })
        ordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, l) in ordered.enumerated() {
            if let idx = lists.firstIndex(where: { $0.id == l.id }) {
                lists[idx].position = Double(i)
            }
        }
        save()
    }

    // MARK: - Tasks

    func tasks(in listId: String, includeCompleted: Bool) -> [TaskItem] {
        let filtered = tasks.filter { $0.listId == listId && (includeCompleted || !$0.completed) }
        return filtered.sorted { $0.position < $1.position }
    }

    func addTask(to listId: String, title: String) {
        let nextPosition = (tasks.filter { $0.listId == listId }.map { $0.position }.max() ?? 0) + 1
        let t = TaskItem(listId: listId, title: title, position: nextPosition)
        tasks.append(t)
        save()
    }

    func updateTask(_ task: TaskItem) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var t = task
        t.updatedAt = Date()
        tasks[idx] = t
        save()
    }

    func deleteTask(id: String) {
        tasks.removeAll { $0.id == id || $0.parentId == id }
        save()
    }

    func moveTask(in listId: String, fromOffsets: IndexSet, toOffset: Int, parentId: String?) {
        var siblings = tasks.filter { $0.listId == listId && $0.parentId == parentId }
        siblings.sort { $0.position < $1.position }
        siblings.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, s) in siblings.enumerated() {
            if let idx = tasks.firstIndex(where: { $0.id == s.id }) {
                tasks[idx].position = Double(i)
            }
        }
        save()
    }

    func indentTask(_ id: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let task = tasks[idx]
        let ordered = tasks(in: task.listId, includeCompleted: true)
        guard let myIndex = ordered.firstIndex(where: { $0.id == id }), myIndex > 0 else { return }
        let prev = ordered[myIndex - 1]
        tasks[idx].parentId = prev.id
        tasks[idx].updatedAt = Date()
        save()
    }

    func outdentTask(_ id: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].parentId = nil
        tasks[idx].updatedAt = Date()
        save()
    }
}
