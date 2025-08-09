import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject var store: AppStore
    @State var task: TaskItem
    @FocusState private var focused: Bool
    @State private var commitWorkItem: DispatchWorkItem? = nil
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Main task content
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
                // Completion checkbox
                Button(action: toggleCompleted) {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.completed ? AppTheme.Colors.completedTask : AppTheme.Colors.primary)
                        .animation(.easeInOut(duration: 0.2), value: task.completed)
                }
                .buttonStyle(IconButtonStyle())

                // Task title
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    TextField("Task title",
                              text: Binding(get: { task.title }, set: { task.title = $0 }),
                              onCommit: commitUpdates)
                        .textFieldStyle(.plain)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(task.completed ? AppTheme.Colors.secondaryText : AppTheme.Colors.primaryText)
                        .strikethrough(task.completed)
                        .focused($focused)
                    
                    // Due date indicator (if exists and not completed)
                    if let dueDate = task.due, !task.completed {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDateText(for: dueDate))
                                .font(AppTheme.Typography.caption)
                        }
                        .foregroundColor(dueDateColor(for: dueDate))
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(dueDateBackgroundColor(for: dueDate))
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }

                Spacer()

                // Action buttons (shown on hover or when task is selected)
                HStack(spacing: AppTheme.Spacing.xs) {
                    if isHovered || focused {
                        DatePicker(
                            "",
                            selection: Binding<Date>(
                                get: { task.due ?? Date() },
                                set: { task.due = $0; commitUpdates() }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .scaleEffect(0.9)
                        
                        Button {
                            task.notes = task.notes.isEmpty ? "Add notes..." : ""
                            commitUpdates()
                        } label: {
                            Image(systemName: task.notes.isEmpty ? "note.text" : "note.text.fill")
                        }
                        .buttonStyle(IconButtonStyle())
                        .help("Add notes")

                        Button {
                            store.deleteTask(id: task.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(IconButtonStyle(color: AppTheme.Colors.error))
                        .help("Delete task")
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            }

            // Notes section
            if !task.notes.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Divider()
                        .background(AppTheme.Colors.cardBorder)
                    
                    TextEditor(text: Binding(get: { task.notes }, set: { task.notes = $0 }))
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .frame(minHeight: 60)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.tertiaryBackground)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        .onChange(of: task.notes, initial: false) { _, _ in
                            debounceCommit()
                        }
                }
            }

            // Task actions bar
            if isHovered || focused {
                HStack(spacing: AppTheme.Spacing.md) {
                    Button { indent() } label: {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "arrow.right.to.line")
                            Text("Indent")
                                .font(AppTheme.Typography.caption)
                        }
                    }
                    .buttonStyle(ModernButtonStyle(isSecondary: true))
                    .help("Make subtask")
                    
                    Button { outdent() } label: {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "arrow.left.to.line")
                            Text("Outdent")
                                .font(AppTheme.Typography.caption)
                        }
                    }
                    .buttonStyle(ModernButtonStyle(isSecondary: true))
                    .help("Remove indent")
                    
                    Spacer()
                    
                    if task.completed {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.completedTask)
                            Text("Completed")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.completedTask)
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
        }
        .taskRowStyle()
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .contentShape(Rectangle())
        .hoverEffect(scaleEffect: 1.01, shadowOpacity: 0.08)
        .onHover { hovering in
            isHovered = hovering
        }
        .transition(.cardFade)
        .onChange(of: task.title, initial: false) { _, _ in
            debounceCommit()
        }
        .onAppear { focused = false }
        .contextMenu {
            Button(task.completed ? "Mark as Incomplete" : "Mark as Complete") { toggleCompleted() }
            Button("Indent") { indent() }
            Button("Outdent") { outdent() }
            Divider()
            Button(role: .destructive) { store.deleteTask(id: task.id) } label: { Text("Delete") }
        }
    }
    
    // MARK: - Helper Methods
    
    private func dueDateText(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Overdue"
        } else if date < now {
            return "Overdue"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func dueDateColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let now = Date()
        
        if date < now && !calendar.isDateInToday(date) {
            return AppTheme.Colors.error
        } else if calendar.isDateInToday(date) {
            return AppTheme.Colors.todayTask
        } else {
            return AppTheme.Colors.secondaryText
        }
    }
    
    private func dueDateBackgroundColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let now = Date()
        
        if date < now && !calendar.isDateInToday(date) {
            return AppTheme.Colors.error.opacity(0.1)
        } else if calendar.isDateInToday(date) {
            return AppTheme.Colors.todayTask.opacity(0.1)
        } else {
            return AppTheme.Colors.tertiaryBackground
        }
    }

    // MARK: - Actions

    private func toggleCompleted() {
        task.completed.toggle()
        commitUpdates()
    }

    private func commitUpdates() {
        store.updateTask(task)
    }

    private func debounceCommit() {
        commitWorkItem?.cancel()
        let work = DispatchWorkItem { commitUpdates() }
        commitWorkItem = work
        // Use explicit time units to avoid the asyncAfter overload error
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400), execute: work)
    }

    private func indent() {
        store.indentTask(task.id)
        if let updated = store.tasks.first(where: { $0.id == task.id }) { task = updated }
    }

    private func outdent() {
        store.outdentTask(task.id)
        if let updated = store.tasks.first(where: { $0.id == task.id }) { task = updated }
    }
}
