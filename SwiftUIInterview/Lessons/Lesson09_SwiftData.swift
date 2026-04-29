import SwiftUI
import SwiftData

// MARK: - Lição 09 — SwiftData
//
// SwiftData (iOS 17+) é o sucessor declarativo do Core Data.
// `@Model` marca uma classe como persistível, `@Query` faz fetch reativo na view.

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
            goal: "Persistir dados localmente com @Model e @Query.",
            exercise: """
            1. Adicione filtro `@Query(filter: #Predicate { !$0.done })` para mostrar só pendentes.
            2. Crie ordenação alternada por título / data via Picker.
            3. Bônus: relacione `TaskItem` a uma `Category` (classe @Model).
            """
        ) {
            HStack {
                TextField("Nova tarefa", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    guard !newTitle.isEmpty else { return }
                    ctx.insert(TaskItem(title: newTitle))
                    newTitle = ""
                }.buttonStyle(.borderedProminent)
            }

            if tasks.isEmpty {
                Text("Sem tarefas").foregroundStyle(.secondary)
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
