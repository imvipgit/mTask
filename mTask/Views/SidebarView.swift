import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var syncEngine: SyncEngine
    @State private var renamingListId: String? = nil
    @State private var newListTitle: String = ""
    @State private var hoveredListId: String? = nil
    @State private var showingSyncView = false

    var body: some View {
        VStack(spacing: 0) {
            // Sidebar header
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Text("mTask")
                            .font(AppTheme.Typography.title)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        // Google sync status indicator
                        googleSyncStatusIndicator
                    }
                    
                    Text("Task Management")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.xs) {
                    // Google sync button
                    Button {
                        showingSyncView = true
                    } label: {
                        Image(systemName: authManager.isSignedIn ? "icloud.fill" : "icloud")
                            .font(.title3)
                            .foregroundColor(authManager.isSignedIn ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                    }
                    .buttonStyle(IconButtonStyle())
                    .help(authManager.isSignedIn ? "Google sync settings" : "Sign in to Google")
                    
                    Button {
                        store.addList()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .buttonStyle(IconButtonStyle())
                    .help("Add new list")
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.secondaryBackground)
            
            Divider()
                .background(AppTheme.Colors.cardBorder)
            
            // Lists section
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(store.lists.sorted(by: { $0.position < $1.position })) { list in
                        listRowView(for: list)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            
            Spacer()
            
            // Bottom stats section
            VStack(spacing: AppTheme.Spacing.sm) {
                Divider()
                    .background(AppTheme.Colors.cardBorder)
                
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("\(totalTasks) tasks")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Text("\(completedTasks) completed")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.completedTask)
                    }
                    
                    Spacer()
                    
                    if completedTasks > 0 {
                        Text("\(Int((Double(completedTasks) / Double(totalTasks)) * 100))%")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(AppTheme.Colors.primaryLight)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .background(AppTheme.Colors.background)
        .sheet(isPresented: $showingSyncView) {
            GoogleSyncView()
                .environmentObject(authManager)
                .environmentObject(syncEngine)
        }
    }
    
    // MARK: - Google Sync Status Indicator
    private var googleSyncStatusIndicator: some View {
        Group {
            if authManager.isSignedIn {
                switch syncEngine.syncStatus {
                case .idle:
                    EmptyView()
                case .syncing:
                    HStack(spacing: AppTheme.Spacing.xs) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Syncing")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                case .success:
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.success)
                        Text("Synced")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                case .error(let message):
                    Button {
                        showingSyncView = true
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.error)
                            Text("Error")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.error)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Sync error: \(message)")
                }
            }
        }
    }
    
    // MARK: - List Row View
    private func listRowView(for list: TaskList) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // List icon
            Image(systemName: "list.bullet")
                .font(.body)
                .foregroundColor(isSelectedList(list) ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                .frame(width: 20)
            
            // List title or text field
            if renamingListId == list.id {
                TextField("List name", text: $newListTitle, onCommit: {
                    store.renameList(id: list.id, title: newListTitle.isEmpty ? "Untitled" : newListTitle)
                    renamingListId = nil
                })
                .textFieldStyle(.plain)
                .font(AppTheme.Typography.body)
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(list.title)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(isSelectedList(list) ? AppTheme.Colors.primary : AppTheme.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(taskCount(for: list)) tasks")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Action buttons (visible on hover)
            if hoveredListId == list.id && renamingListId != list.id {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Button {
                        renamingListId = list.id
                        newListTitle = list.title
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(IconButtonStyle())
                    .help("Rename list")
                    
                    Button {
                        store.deleteList(id: list.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(IconButtonStyle(color: AppTheme.Colors.error))
                    .help("Delete list")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(isSelectedList(list) ? AppTheme.Colors.primaryLight : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(
                    isSelectedList(list) ? AppTheme.Colors.primary.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedListId = list.id
        }
        .onHover { hovering in
            hoveredListId = hovering ? list.id : nil
        }
        .hoverEffect(scaleEffect: 1.005, shadowOpacity: 0.05)
        .contextMenu {
            Button("Rename") {
                renamingListId = list.id
                newListTitle = list.title
            }
            Button(role: .destructive) {
                store.deleteList(id: list.id)
            } label: { Text("Delete") }
        }
        .animation(.smoothEaseInOut, value: hoveredListId)
        .animation(.smoothEaseInOut, value: isSelectedList(list))
    }
    
    // MARK: - Helper Methods
    private func isSelectedList(_ list: TaskList) -> Bool {
        return store.selectedListId == list.id
    }
    
    private func taskCount(for list: TaskList) -> Int {
        return store.tasks.filter { $0.listId == list.id }.count
    }
    
    private var totalTasks: Int {
        return store.tasks.count
    }
    
    private var completedTasks: Int {
        return store.tasks.filter { $0.completed }.count
    }
}
