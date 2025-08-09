import SwiftUI

struct QuickAddMenuBar: View {
    @EnvironmentObject var store: AppStore
    @State private var title: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("List", selection: Binding(
                get: { store.selectedListId ?? store.lists.first?.id ?? "" },
                set: { store.selectedListId = $0 }
            )) {
                ForEach(store.lists.sorted(by: { $0.position < $1.position })) { list in
                    Text(list.title).tag(list.id)
                }
            }
            TextField("Quick add task", text: $title, onCommit: add)
            Button("Add", action: add)
        }
        .padding(12)
        .frame(width: 300)
    }

    private func add() {
        guard let listId = store.selectedListId, !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        store.addTask(to: listId, title: title)
        title = ""
    }
}