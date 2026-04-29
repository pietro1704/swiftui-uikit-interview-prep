import SwiftUI

// MARK: - Lesson 02 — List, ForEach, Identifiable
//
// - `List` builds reusable cells with native separators and swipe support.
// - `Identifiable` lets ForEach skip verbose key paths.
// - `.swipeActions` is the modern replacement for UIKit's edit actions.

struct Fruit: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var emoji: String
}

struct Lesson02View: View {
    @State private var fruits: [Fruit] = [
        .init(name: "Banana", emoji: "🍌"),
        .init(name: "Apple",  emoji: "🍎"),
        .init(name: "Grape",  emoji: "🍇")
    ]
    @State private var newFruit = ""

    var body: some View {
        LessonScaffold(
            title: "02 — Lists",
            goal: "Dynamic lists with add, remove, move and swipe actions.",
            exercise: """
            1. Add a "Favorite" `.swipeActions(edge: .leading)` button that prefixes ⭐ to the name.
            2. Implement `onMove` for reordering (needs `EditButton`).
            3. Bonus: group favorited fruits into a top section using two Sections.
            """
        ) {
            HStack {
                TextField("New fruit", text: $newFruit)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    guard !newFruit.isEmpty else { return }
                    fruits.append(.init(name: newFruit, emoji: "🍏"))
                    newFruit = ""
                }
                .buttonStyle(.borderedProminent)
            }

            VStack(spacing: 0) {
                ForEach(fruits) { fruit in
                    HStack {
                        Text(fruit.emoji)
                        Text(fruit.name)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .swipeActions {
                        Button(role: .destructive) {
                            fruits.removeAll { $0.id == fruit.id }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                    Divider()
                }
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))

            // TODO: replace the VStack+ForEach with a real `List` plus .onDelete and .onMove
            // List { ForEach(fruits) { ... }.onDelete { fruits.remove(atOffsets: $0) } }
        }
    }
}

#Preview { NavigationStack { Lesson02View() } }
