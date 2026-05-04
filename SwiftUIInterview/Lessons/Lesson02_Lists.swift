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
//
// Layout note: this lesson skips `LessonScaffold` because a `List` inside a
// `ScrollView` collapses to height 0. Instead, `List` is the root scrollable
// and we pin the goal/exercise boxes via `.safeAreaInset` — the idiomatic
// SwiftUI way to attach non-scrolling chrome to a scrollable container.

struct Fruit: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var emoji: String
    var favorite = false
}

struct Lesson02View: View {
    @State private var fruits: [Fruit] = [
        .init(name: "Mango", emoji: "🥭"),
        .init(name: "Apple", emoji: "🍎"),
        .init(name: "Grape", emoji: "🍇"),
    ]
    @State private var newFruit = ""

    private var favorites: [Fruit] { fruits.filter(\.favorite) }
    private var others: [Fruit] { fruits.filter { !$0.favorite } }

    var body: some View {
        HStack {
            TextField("New fruit", text: $newFruit)
                .textFieldStyle(.roundedBorder)
            Button("Add", action: addFruit)
                .buttonStyle(.borderedProminent)
        }.padding()
        
        List(fruits){ fruit in
            row(fruit)
        }
        .navigationTitle("02 — Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .safeAreaInset(edge: .top) {
            LessonGoalBox(goal: "Dynamic lists with add, remove, move and swipe actions.")
                .padding(.horizontal)
                .padding(.top, 8)
                .background(.background)
        }
        
        if !favorites.isEmpty {
            Section("Favorites ⭐") {
                ForEach(favorites) { fruit in row(fruit) }
                    .onDelete { delete(from: favorites, at: $0) }
            }
        }
        
        //            Section("All") {
//        ForEach(others) { fruit in row(fruit) }
//            .onDelete { delete(from: others, at: $0) }
//            .onMove { source, dest in moveOthers(from: source, to: dest) }
        //            }
        LessonExerciseBox(
            exercise: """
                    1. Add a "Favorite" `.swipeActions(edge: .leading)` button that prefixes ⭐ to the name.
                    2. Implement `onMove` for reordering (needs `EditButton`).
                    3. Bonus: group favorited fruits into a top section using two Sections.
                    """
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(.background)
        .hotReload()
    }

    // MARK: - Row

    private func row(_ fruit: Fruit) -> some View {
        HStack {
            Text(fruit.emoji)
            Text((fruit.favorite ? "⭐ " : "") + fruit.name)
            Spacer()
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleFavorite(fruit)
            } label: {
                Label(
                    fruit.favorite ? "Unfavorite" : "Favorite",
                    systemImage: fruit.favorite ? "star.slash" : "star"
                )
            }
            .tint(.yellow)
        }
    }

    // MARK: - Mutations

    private func addFruit() {
        let trimmed = newFruit.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        fruits.append(.init(name: trimmed, emoji: "🍏"))
        newFruit = ""
    }

    private func toggleFavorite(_ fruit: Fruit) {
        guard let i = fruits.firstIndex(where: { $0.id == fruit.id }) else { return }
        fruits[i].favorite.toggle()
    }

    private func delete(from slice: [Fruit], at indexSet: IndexSet) {
        let idsToRemove = Set(indexSet.map { slice[$0].id })
        fruits.removeAll { idsToRemove.contains($0.id) }
    }

    /// Reorder within "All" section. ForEach offsets are relative to `others`,
    /// so we reorder that slice and splice back into `fruits`, keeping
    /// favorited items at their original absolute positions.
    private func moveOthers(from source: IndexSet, to destination: Int) {
        var working = others
        working.move(fromOffsets: source, toOffset: destination)
        var iter = working.makeIterator()
        fruits = fruits.map { $0.favorite ? $0 : (iter.next() ?? $0) }
    }
}

#Preview { Lesson02View() }
