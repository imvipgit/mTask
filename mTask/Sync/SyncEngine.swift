import Foundation

// MARK: - Sync Status

enum SyncStatus {
    case idle
    case syncing
    case success
    case error(String)
}

// MARK: - Sync Statistics

struct SyncStats {
    let listsDownloaded: Int
    let listsUploaded: Int
    let tasksDownloaded: Int
    let tasksUploaded: Int
    let conflicts: Int
    let errors: Int
    
    static let empty = SyncStats(listsDownloaded: 0, listsUploaded: 0, tasksDownloaded: 0, tasksUploaded: 0, conflicts: 0, errors: 0)
}

// MARK: - Sync Engine

final class SyncEngine: ObservableObject {
    static let shared = SyncEngine()
    
    @Published var lastSync: Date? = nil
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncStats: SyncStats = .empty
    @Published var isSyncEnabled: Bool = true
    
    private let auth = AuthManager.shared
    private let api = GoogleTasksAPI.shared
    private var syncTask: Task<Void, Never>?
    
    // Google Task List ID mapping to local list IDs
    private var listMapping: [String: String] = [:] // local ID -> Google ID
    private var taskMapping: [String: String] = [:] // local ID -> Google ID
    
    private init() {
        loadMappings()
        
        // Auto-sync when authentication state changes
        auth.$isSignedIn.sink { [weak self] isSignedIn in
            if isSignedIn {
                Task {
                    await self?.syncNow()
                }
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Public Methods
    
    func syncNow() async {
        guard isSyncEnabled && auth.isSignedIn else { return }
        
        // Cancel any existing sync
        syncTask?.cancel()
        
        syncTask = Task {
            await performSync()
        }
        
        await syncTask?.value
    }
    
    func enableSync() {
        isSyncEnabled = true
        if auth.isSignedIn {
            Task {
                await syncNow()
            }
        }
    }
    
    func disableSync() {
        isSyncEnabled = false
        syncTask?.cancel()
        syncStatus = .idle
    }
    
    // MARK: - Private Sync Implementation
    
    private func performSync() async {
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            let stats = try await performBidirectionalSync()
            await MainActor.run {
                self.lastSync = Date()
                self.lastSyncStats = stats
                self.syncStatus = .success
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    private func performBidirectionalSync() async throws -> SyncStats {
        let token = try await auth.getAccessToken()
        
        // 1. Sync task lists
        let listStats = try await syncTaskLists(token: token)
        
        // 2. Sync tasks for each list
        let taskStats = try await syncTasks(token: token)
        
        return SyncStats(
            listsDownloaded: listStats.listsDownloaded,
            listsUploaded: listStats.listsUploaded,
            tasksDownloaded: taskStats.tasksDownloaded,
            tasksUploaded: taskStats.tasksUploaded,
            conflicts: listStats.conflicts + taskStats.conflicts,
            errors: listStats.errors + taskStats.errors
        )
    }
    
    // MARK: - Task Lists Sync
    
    private func syncTaskLists(token: String) async throws -> SyncStats {
        var stats = SyncStats.empty
        
        // Get remote task lists
        let (remoteLists, _) = try await api.listTaskLists(token: token)
        
        // Get local lists from app store
        let localLists = await getLocalLists()
        
        // Sync remote lists to local
        for remoteList in remoteLists {
            if let localListId = await findLocalListByGoogleId(remoteList.id) {
                // Update existing local list
                await updateLocalList(localListId, from: remoteList)
            } else {
                // Create new local list
                let localListId = await createLocalList(from: remoteList)
                listMapping[localListId] = remoteList.id
            }
            stats = SyncStats(
                listsDownloaded: stats.listsDownloaded + 1,
                listsUploaded: stats.listsUploaded,
                tasksDownloaded: stats.tasksDownloaded,
                tasksUploaded: stats.tasksUploaded,
                conflicts: stats.conflicts,
                errors: stats.errors
            )
        }
        
        // Sync local lists to remote
        for localList in localLists {
            if let googleId = listMapping[localList.id] {
                // Update existing remote list
                let remoteList = remoteLists.first { $0.id == googleId }
                if let remoteList = remoteList,
                   localList.title != remoteList.title,
                   let remoteUpdated = remoteList.updated,
                   localList.updatedAt > remoteUpdated {
                    
                    _ = try await api.updateTaskList(
                        listId: googleId,
                        title: localList.title,
                        token: token,
                        ifMatch: remoteList.etag
                    )
                    stats = SyncStats(
                        listsDownloaded: stats.listsDownloaded,
                        listsUploaded: stats.listsUploaded + 1,
                        tasksDownloaded: stats.tasksDownloaded,
                        tasksUploaded: stats.tasksUploaded,
                        conflicts: stats.conflicts,
                        errors: stats.errors
                    )
                }
            } else {
                // Create new remote list
                let newRemoteList = try await api.createTaskList(title: localList.title, token: token)
                listMapping[localList.id] = newRemoteList.id
                stats = SyncStats(
                    listsDownloaded: stats.listsDownloaded,
                    listsUploaded: stats.listsUploaded + 1,
                    tasksDownloaded: stats.tasksDownloaded,
                    tasksUploaded: stats.tasksUploaded,
                    conflicts: stats.conflicts,
                    errors: stats.errors
                )
            }
        }
        
        saveMappings()
        return stats
    }
    
    // MARK: - Tasks Sync
    
    private func syncTasks(token: String) async throws -> SyncStats {
        var stats = SyncStats.empty
        
        let localLists = await getLocalLists()
        
        for localList in localLists {
            guard let googleListId = listMapping[localList.id] else { continue }
            
            // Get remote tasks for this list
            let (remoteTasks, _) = try await api.listTasks(
                listId: googleListId,
                showCompleted: true,
                showDeleted: false,
                token: token
            )
            
            // Get local tasks for this list
            let localTasks = await getLocalTasks(for: localList.id)
            
            // Sync remote tasks to local
            for remoteTask in remoteTasks {
                if let localTaskId = await findLocalTaskByGoogleId(remoteTask.id) {
                    // Update existing local task
                    let conflicted = await updateLocalTask(localTaskId, from: remoteTask, listId: localList.id)
                    if conflicted {
                        stats = SyncStats(
                            listsDownloaded: stats.listsDownloaded,
                            listsUploaded: stats.listsUploaded,
                            tasksDownloaded: stats.tasksDownloaded,
                            tasksUploaded: stats.tasksUploaded,
                            conflicts: stats.conflicts + 1,
                            errors: stats.errors
                        )
                    }
                } else {
                    // Create new local task
                    let localTaskId = await createLocalTask(from: remoteTask, listId: localList.id)
                    taskMapping[localTaskId] = remoteTask.id
                }
                stats = SyncStats(
                    listsDownloaded: stats.listsDownloaded,
                    listsUploaded: stats.listsUploaded,
                    tasksDownloaded: stats.tasksDownloaded + 1,
                    tasksUploaded: stats.tasksUploaded,
                    conflicts: stats.conflicts,
                    errors: stats.errors
                )
            }
            
            // Sync local tasks to remote
            for localTask in localTasks {
                if let googleTaskId = taskMapping[localTask.id] {
                    // Update existing remote task
                    let remoteTask = remoteTasks.first { $0.id == googleTaskId }
                    if let remoteTask = remoteTask,
                       await shouldUpdateRemoteTask(localTask, remoteTask) {
                        
                        let gTask = convertToGoogleTask(localTask)
                        _ = try await api.updateTask(
                            listId: googleListId,
                            taskId: googleTaskId,
                            task: gTask,
                            token: token,
                            ifMatch: remoteTask.etag
                        )
                        stats = SyncStats(
                            listsDownloaded: stats.listsDownloaded,
                            listsUploaded: stats.listsUploaded,
                            tasksDownloaded: stats.tasksDownloaded,
                            tasksUploaded: stats.tasksUploaded + 1,
                            conflicts: stats.conflicts,
                            errors: stats.errors
                        )
                    }
                } else {
                    // Create new remote task
                    let gTask = convertToGoogleTask(localTask)
                    let parentGoogleId = localTask.parentId.flatMap { taskMapping[$0] }
                    
                    let newRemoteTask = try await api.insertTask(
                        listId: googleListId,
                        task: gTask,
                        parent: parentGoogleId,
                        token: token
                    )
                    taskMapping[localTask.id] = newRemoteTask.id
                    stats = SyncStats(
                        listsDownloaded: stats.listsDownloaded,
                        listsUploaded: stats.listsUploaded,
                        tasksDownloaded: stats.tasksDownloaded,
                        tasksUploaded: stats.tasksUploaded + 1,
                        conflicts: stats.conflicts,
                        errors: stats.errors
                    )
                }
            }
        }
        
        saveMappings()
        return stats
    }
    
    // MARK: - Helper Methods
    
    private func convertToGoogleTask(_ localTask: TaskItem) -> GTask {
        return GTask(
            id: taskMapping[localTask.id] ?? "",
            title: localTask.title,
            notes: localTask.notes.isEmpty ? nil : localTask.notes,
            due: localTask.due,
            status: localTask.completed ? "completed" : "needsAction",
            parent: localTask.parentId.flatMap { taskMapping[$0] },
            position: String(localTask.position),
            updated: localTask.updatedAt,
            deleted: false,
            etag: nil
        )
    }
    
    private func convertToLocalTask(_ gTask: GTask, listId: String) -> TaskItem {
        let parentId = gTask.parent.flatMap { googleId in
            taskMapping.first { $0.value == googleId }?.key
        }
        
        return TaskItem(
            id: UUID().uuidString,
            listId: listId,
            title: gTask.title ?? "",
            notes: gTask.notes ?? "",
            due: gTask.due,
            completed: gTask.status == "completed",
            parentId: parentId,
            position: Double(gTask.position ?? "0") ?? 0,
            updatedAt: gTask.updated ?? Date()
        )
    }
    
    private func shouldUpdateRemoteTask(_ localTask: TaskItem, _ remoteTask: GTask) async -> Bool {
        // Simple conflict resolution: local wins if updated more recently
        guard let remoteUpdated = remoteTask.updated else { return true }
        return localTask.updatedAt > remoteUpdated
    }
    
    // MARK: - Local Data Access (These would interface with AppStore)
    
    private func getLocalLists() async -> [TaskList] {
        // This would get lists from AppStore
        // For now, return empty array - implement when integrating with UI
        return []
    }
    
    private func getLocalTasks(for listId: String) async -> [TaskItem] {
        // This would get tasks from AppStore for specific list
        // For now, return empty array - implement when integrating with UI
        return []
    }
    
    private func findLocalListByGoogleId(_ googleId: String) async -> String? {
        return listMapping.first { $0.value == googleId }?.key
    }
    
    private func findLocalTaskByGoogleId(_ googleId: String) async -> String? {
        return taskMapping.first { $0.value == googleId }?.key
    }
    
    private func updateLocalList(_ localId: String, from remoteList: GTaskList) async {
        // Update local list with remote data
        // Implement when integrating with UI
    }
    
    private func createLocalList(from remoteList: GTaskList) async -> String {
        // Create new local list from remote data
        // Return the new local list ID
        // Implement when integrating with UI
        return UUID().uuidString
    }
    
    private func updateLocalTask(_ localId: String, from remoteTask: GTask, listId: String) async -> Bool {
        // Update local task with remote data
        // Return true if there was a conflict
        // Implement when integrating with UI
        return false
    }
    
    private func createLocalTask(from remoteTask: GTask, listId: String) async -> String {
        // Create new local task from remote data
        // Return the new local task ID
        let localTask = convertToLocalTask(remoteTask, listId: listId)
        // Implement when integrating with UI
        return localTask.id
    }
    
    // MARK: - Mapping Persistence
    
    private func loadMappings() {
        if let listData = UserDefaults.standard.data(forKey: "google_list_mapping"),
           let lists = try? JSONDecoder().decode([String: String].self, from: listData) {
            listMapping = lists
        }
        
        if let taskData = UserDefaults.standard.data(forKey: "google_task_mapping"),
           let tasks = try? JSONDecoder().decode([String: String].self, from: taskData) {
            taskMapping = tasks
        }
    }
    
    private func saveMappings() {
        if let listData = try? JSONEncoder().encode(listMapping) {
            UserDefaults.standard.set(listData, forKey: "google_list_mapping")
        }
        
        if let taskData = try? JSONEncoder().encode(taskMapping) {
            UserDefaults.standard.set(taskData, forKey: "google_task_mapping")
        }
    }
}

// MARK: - Extensions

import Combine