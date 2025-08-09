import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            if let listId = store.selectedListId,
               let list = store.lists.first(where: { $0.id == listId }) {
                TaskListView(list: list)
            } else {
                emptyStateView
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Illustration area
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.Colors.primary.opacity(0.6))
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Welcome to mTask")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text("Create your first task list to get started organizing your work")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                }
            }
            
            // Action button
            Button {
                store.addList(title: "My Tasks")
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First List")
                }
                .font(AppTheme.Typography.headline)
            }
            .buttonStyle(ModernButtonStyle())
            
            // Quick tips
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Quick Tips:")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    TipRow(icon: "plus.circle", text: "Click + to add new lists and tasks")
                    TipRow(icon: "arrow.right.to.line", text: "Use indent/outdent to create subtasks")
                    TipRow(icon: "calendar", text: "Set due dates to stay organized")
                    TipRow(icon: "note.text", text: "Add notes for detailed task information")
                }
            }
            .cardStyle()
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 20)
            
            Text(text)
                .font(AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }
}
