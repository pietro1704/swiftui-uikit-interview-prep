import SwiftUI

// MARK: - Lição 02 — List, ForEach, Identifiable
//
// - `List` cria células reutilizáveis, com separadores e swipe nativo.
// - `Identifiable` evita key paths verbosos no ForEach.
// - `.swipeActions` substitui o antigo `editActions` do UIKit.

struct Fruit: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var emoji: String
}

struct Lesson02View: View {
    @State private var fruits: [Fruit] = [
        .init(name: "Banana", emoji: "🍌"),
        .init(name: "Maçã", emoji: "🍎"),
        .init(name: "Uva", emoji: "🍇")
    ]
    @State private var newFruit = ""

    var body: some View {
        LessonScaffold(
            title: "02 — Lists",
            goal: "Listas dinâmicas com adicionar, remover, mover e swipe actions.",
            exercise: """
            1. Adicione um botão "Favoritar" via `.swipeActions(edge: .leading)` que prefixa ⭐ no nome.
            2. Implemente `onMove` para reordenar (precisa de `EditButton`).
            3. Bônus: agrupe frutas favoritas no topo usando duas Sections.
            """
        ) {
            HStack {
                TextField("Nova fruta", text: $newFruit)
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
                        } label: { Label("Apagar", systemImage: "trash") }
                    }
                    Divider()
                }
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))

            // TODO: troque o VStack+ForEach por um List nativo com .onDelete e .onMove
            // List { ForEach(fruits) { ... }.onDelete { fruits.remove(atOffsets: $0) } }
        }
    }
}

#Preview { NavigationStack { Lesson02View() } }
