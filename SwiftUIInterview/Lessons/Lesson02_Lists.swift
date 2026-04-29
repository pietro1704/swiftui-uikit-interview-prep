import SwiftUI

// MARK: - Lesson 02 — List, ForEach, Identifiable
//
// `List` is a container that renders children as reusable cells with native
// separators, swipe actions and selection — same idea as UITableView.
//
// Three flavors:
//   1. Static rows:        List { Text("A"); Text("B") }
//   2. Data-driven:        List(items) { item in Text(item.name) }
//   3. With ForEach:       List { ForEach(items) { ... }.onDelete { ... } }
//
// Important: `.onDelete` and `.onMove` are modifiers of **ForEach**, not List.

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

            // Real List with ForEach, .onDelete and .onMove.
            // Tap the Edit button to enable reorder/delete mode.
            List {
                ForEach(fruits) { fruit in
                    HStack {
                        Text(fruit.emoji)
                        Text(fruit.name)
                        Spacer()
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            fruits.removeAll { $0.id == fruit.id }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                .onDelete { offsets in fruits.remove(atOffsets: offsets) }
                .onMove   { src, dst in fruits.move(fromOffsets: src, toOffset: dst) }
            }
            .frame(minHeight: 240)
            .scrollContentBackground(.hidden)
            .toolbar { EditButton() }

            SolutionDisclosure(title: "Show solution (favorites + sections)") {
                CodeBlock("""
                struct Fruit: Identifiable, Hashable {
                    let id = UUID()
                    var name: String
                    var emoji: String
                    var favorite = false
                }

                List {
                    let favs = fruits.filter(\\.favorite)
                    let rest = fruits.filter { !$0.favorite }

                    Section("Favorites") {
                        ForEach(favs) { fruit in row(fruit) }
                    }
                    Section("All") {
                        ForEach(rest) { fruit in row(fruit) }
                    }
                }

                @ViewBuilder
                func row(_ fruit: Fruit) -> some View {
                    HStack { Text(fruit.emoji); Text(fruit.name) }
                        .swipeActions(edge: .leading) {
                            Button {
                                if let i = fruits.firstIndex(where: { $0.id == fruit.id }) {
                                    fruits[i].favorite.toggle()
                                }
                            } label: { Label("Favorite", systemImage: "star") }
                            .tint(.yellow)
                        }
                }
                """)
            }
        }
    }
}

#Preview { NavigationStack { Lesson02View() } }
