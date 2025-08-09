import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var store: AppStore
    var list: TaskList

    @State private var newTaskTitle: String = ""
    @FocusState private var isAddingTask: Bool
    @State private var showingStats = false

    var body: some View {
        VStack(spacing: 0) {
            // Modern header with enhanced styling
            headerView
            
            // Task content area
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    TaskSection(listId: list.id, parentId: nil)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack {
                    // Stats toggle button
                    Button {
                        showingStats.toggle()
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                    .help("Show statistics")
                    
                    // Show completed toggle
                    Toggle(isOn: $store.showCompleted) {
                        Image(systemName: store.showCompleted ? "eye" : "eye.slash")
                    }
                    .help("Show completed tasks")
                    .toggleStyle(.button)
                }
            }
        }
        .navigationTitle("")
        .onAppear { if store.selectedListId != list.id { store.selectedListId = list.id } }
        .sheet(isPresented: $showingStats) {
            TaskStatsView(list: list)
        }
    }

    private var headerView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // List title and info
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(list.title)
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    HStack(spacing: AppTheme.Spacing.md) {
                        Label("\(incompleteTasks) remaining", systemImage: "circle")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        if completedTasksInList > 0 {
                            Label("\(completedTasksInList) completed", systemImage: "checkmark.circle.fill")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.completedTask)
                        }
                    }
                }
                
                Spacer()
                
                // Progress indicator
                if totalTasksInList > 0 {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("\(Int((Double(completedTasksInList) / Double(totalTasksInList)) * 100))%")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        ProgressView(value: Double(completedTasksInList), total: Double(totalTasksInList))
                            .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.primary))
                            .frame(width: 80)
                    }
                }
            }
            
            // Quick add task bar
            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    TextField("Add a new task...", text: $newTaskTitle)
                        .textFieldStyle(.plain)
                        .font(AppTheme.Typography.body)
                        .focused($isAddingTask)
                        .onSubmit {
                            addTask()
                        }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .stroke(
                            isAddingTask ? AppTheme.Colors.primary : AppTheme.Colors.cardBorder,
                            lineWidth: isAddingTask ? 2 : 1
                        )
                )
                .cornerRadius(AppTheme.CornerRadius.large)
                .animation(.easeInOut(duration: 0.2), value: isAddingTask)
                
                if !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingTask {
                    Button("Add") {
                        addTask()
                    }
                    .buttonStyle(ModernButtonStyle())
                    .keyboardShortcut(.return, modifiers: [.command])
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.secondaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.Colors.cardBorder),
            alignment: .bottom
        )
    }

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            store.addTask(to: list.id, title: trimmed)
            newTaskTitle = ""
            isAddingTask = false
        }
    }
    
    // MARK: - Computed Properties
    private var totalTasksInList: Int {
        store.tasks.filter { $0.listId == list.id }.count
    }
    
    private var completedTasksInList: Int {
        store.tasks.filter { $0.listId == list.id && $0.completed }.count
    }
    
    private var incompleteTasks: Int {
        totalTasksInList - completedTasksInList
    }
}

private struct TaskSection: View {
    @EnvironmentObject var store: AppStore
    var listId: String
    var parentId: String?

    var body: some View {
        let items = store.tasks.filter { $0.listId == listId && $0.parentId == parentId && (store.showCompleted || !$0.completed) }
            .sorted(by: { $0.position < $1.position })

        LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    TaskRowView(task: item)
                    
                    // Subtasks section
                    if hasChildren(item) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            TaskSection(listId: listId, parentId: item.id)
                        }
                        .padding(.leading, AppTheme.Spacing.xl)
                        .overlay(
                            Rectangle()
                                .frame(width: 2)
                                .foregroundColor(AppTheme.Colors.cardBorder)
                                .padding(.leading, AppTheme.Spacing.lg),
                            alignment: .leading
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: hasChildren(item))
            }
            .onMove { indices, newOffset in
                store.moveTask(in: listId, fromOffsets: indices, toOffset: newOffset, parentId: parentId)
            }
        }
    }

    private func hasChildren(_ item: TaskItem) -> Bool {
        store.tasks.contains(where: { $0.parentId == item.id })
    }
}