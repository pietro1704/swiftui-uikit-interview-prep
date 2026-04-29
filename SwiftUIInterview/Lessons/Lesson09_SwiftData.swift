import SwiftUI
import SwiftData

// MARK: - Lesson 09 — SwiftData
//
// SwiftData (iOS 17+) is the declarative successor to Core Data.
// `@Model` marks a class as persistable; `@Query` does a reactive fetch in the view.

@Model
final class TaskItem {
    var title: String
    var done: Bool
    var createdAt: Date

    init(title: String, done: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.done = done
        self.createdAt = createdAt
    }
}

struct Lesson09View: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @State private var newTitle = ""

    var body: some View {
        LessonScaffold(
            title: "09 — SwiftData",
            goal: "Persist data locally with @Model and @Query.",
            exercise: """
            1. Add a `@Query(filter: #Predicate { !$0.done })` to show only pending tasks.
            2. Toggle ordering between title / date via a Picker.
            3. Bonus: relate `TaskItem` to a `Category` (an `@Model` class).
            """
        ) {
            HStack {
                TextField("New task", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    guard !newTitle.isEmpty else { return }
                    ctx.insert(TaskItem(title: newTitle))
                    newTitle = ""
                }.buttonStyle(.borderedProminent)
            }

            if tasks.isEmpty {
                Text("No tasks yet").foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(tasks) { task in
                        HStack {
                            Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.done ? .green : .secondary)
                                .onTapGesture { task.done.toggle() }
                            Text(task.title)
                                .strikethrough(task.done)
                            Spacer()
                            Button(role: .destructive) {
                                ctx.delete(task)
                            } label: { Image(systemName: "trash") }
                        }
                        .padding(10)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { Lesson09View() }
        .modelContainer(for: TaskItem.self, inMemory: true)
}
