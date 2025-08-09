import SwiftUI

struct TaskStatsView: View {
    @EnvironmentObject var store: AppStore
    let list: TaskList
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Overview stats
                    overviewSection
                    
                    // Progress visualization
                    progressSection
                    
                    // Due dates breakdown
                    dueDatesSection
                    
                    // Recent activity
                    activitySection
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        // This will be handled by the parent view's sheet dismissal
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Overview")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                StatCard(
                    title: "Total Tasks",
                    value: "\(totalTasks)",
                    icon: "list.bullet",
                    color: AppTheme.Colors.primary
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(completedTasks)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.Colors.completedTask
                )
                
                StatCard(
                    title: "Remaining",
                    value: "\(remainingTasks)",
                    icon: "circle",
                    color: AppTheme.Colors.warning
                )
                
                StatCard(
                    title: "Completion Rate",
                    value: completionRate,
                    icon: "percent",
                    color: AppTheme.Colors.primary
                )
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Progress")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            VStack(spacing: AppTheme.Spacing.lg) {
                // Progress bar
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Completion Progress")
                            .font(AppTheme.Typography.headline)
                        Spacer()
                        Text(completionRate)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    ProgressView(value: Double(completedTasks), total: Double(totalTasks))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.primary))
                        .frame(height: 8)
                        .background(AppTheme.Colors.tertiaryBackground)
                        .cornerRadius(4)
                }
                .cardStyle()
                .padding(AppTheme.Spacing.md)
            }
        }
    }
    
    // MARK: - Due Dates Section
    private var dueDatesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Due Dates")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                DueDateRow(
                    title: "Overdue",
                    count: overdueTasks,
                    color: AppTheme.Colors.error
                )
                
                DueDateRow(
                    title: "Due Today",
                    count: todayTasks,
                    color: AppTheme.Colors.todayTask
                )
                
                DueDateRow(
                    title: "Due This Week",
                    count: thisWeekTasks,
                    color: AppTheme.Colors.warning
                )
                
                DueDateRow(
                    title: "No Due Date",
                    count: noDueDateTasks,
                    color: AppTheme.Colors.secondaryText
                )
            }
            .cardStyle()
            .padding(AppTheme.Spacing.md)
        }
    }
    
    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Recent Activity")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(recentTasks.prefix(5), id: \.id) { task in
                    HStack {
                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.completed ? AppTheme.Colors.completedTask : AppTheme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(task.title)
                                .font(AppTheme.Typography.body)
                                .strikethrough(task.completed)
                            
                            Text("Updated \(task.updatedAt, style: .relative)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                    
                    if task.id != recentTasks.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .cardStyle()
            .padding(AppTheme.Spacing.md)
        }
    }
    
    // MARK: - Computed Properties
    private var tasksInList: [TaskItem] {
        store.tasks.filter { $0.listId == list.id }
    }
    
    private var totalTasks: Int {
        tasksInList.count
    }
    
    private var completedTasks: Int {
        tasksInList.filter { $0.completed }.count
    }
    
    private var remainingTasks: Int {
        totalTasks - completedTasks
    }
    
    private var completionRate: String {
        guard totalTasks > 0 else { return "0%" }
        let rate = Double(completedTasks) / Double(totalTasks) * 100
        return String(format: "%.0f%%", rate)
    }
    
    private var overdueTasks: Int {
        let now = Date()
        return tasksInList.filter { task in
            guard let due = task.due, !task.completed else { return false }
            return due < now && !Calendar.current.isDateInToday(due)
        }.count
    }
    
    private var todayTasks: Int {
        tasksInList.filter { task in
            guard let due = task.due, !task.completed else { return false }
            return Calendar.current.isDateInToday(due)
        }.count
    }
    
    private var thisWeekTasks: Int {
        let now = Date()
        let weekLater = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        
        return tasksInList.filter { task in
            guard let due = task.due, !task.completed else { return false }
            return due > now && due <= weekLater && !Calendar.current.isDateInToday(due)
        }.count
    }
    
    private var noDueDateTasks: Int {
        tasksInList.filter { $0.due == nil && !$0.completed }.count
    }
    
    private var recentTasks: [TaskItem] {
        tasksInList.sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(value)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
        .padding(AppTheme.Spacing.md)
    }
}

struct DueDateRow: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Spacer()
            
            Text("\(count)")
                .font(AppTheme.Typography.headline)
                .foregroundColor(color)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}
