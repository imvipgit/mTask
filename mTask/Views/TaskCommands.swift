import SwiftUI

struct TaskCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Task") {
                NotificationCenter.default.post(name: .newTask, object: nil)
            }.keyboardShortcut("n", modifiers: .command)

            Button("New List") {
                NotificationCenter.default.post(name: .newList, object: nil)
            }.keyboardShortcut("l", modifiers: .command)
        }

        CommandGroup(replacing: .textEditing) {
            Button("Complete / Uncomplete") {
                NotificationCenter.default.post(name: .toggleComplete, object: nil)
            }.keyboardShortcut("k", modifiers: [.command, .shift])

            Button("Indent") {
                NotificationCenter.default.post(name: .indent, object: nil)
            }.keyboardShortcut(.tab, modifiers: [])

            Button("Outdent") {
                NotificationCenter.default.post(name: .outdent, object: nil)
            }.keyboardShortcut(.tab, modifiers: [.shift])
        }
    }
}

extension Notification.Name {
    static let newTask = Notification.Name("TasksForMac.NewTask")
    static let newList = Notification.Name("TasksForMac.NewList")
    static let toggleComplete = Notification.Name("TasksForMac.ToggleComplete")
    static let indent = Notification.Name("TasksForMac.Indent")
    static let outdent = Notification.Name("TasksForMac.Outdent")
}