import SwiftUI

// MARK: - Lição 03 — NavigationStack
//
// Substitui NavigationView (deprecated). Push declarativo via:
//  - NavigationLink(value:) { label } + .navigationDestination(for:)
//  - NavigationStack(path:) para navegação programática

enum Route: Hashable {
    case detail(Int)
    case profile(String)
}

struct Lesson03View: View {
    @State private var path: [Route] = []

    var body: some View {
        LessonScaffold(
            title: "03 — Navigation",
            goal: "Navegação tipada e controle programático do path.",
            exercise: """
            1. Adicione um botão "Pop to root" que esvazia `path`.
            2. Crie um deep link: tap leva para detail(7) e depois profile("Ana").
            3. Use `.toolbar` para botão de voltar customizado.
            """
        ) {
            VStack(spacing: 12) {
                ForEach(1...3, id: \.self) { i in
                    Button("Push detail \(i)") {
                        path.append(.detail(i))
                    }
                    .buttonStyle(.bordered)
                }
                Button("Deep link → detail(7) → profile(Ana)") {
                    path = [.detail(7), .profile("Ana")]
                }
                .buttonStyle(.borderedProminent)

                Text("Path atual: \(path.count) níveis")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .detail(let id):
                DetailView(id: id, path: $path)
            case .profile(let name):
                Text("Profile: \(name)").font(.title)
            }
        }
    }
}

private struct DetailView: View {
    let id: Int
    @Binding var path: [Route]

    var body: some View {
        VStack(spacing: 16) {
            Text("Detail #\(id)").font(.largeTitle)
            Button("Ir para profile") { path.append(.profile("User \(id)")) }
            Button("Pop to root") { path.removeAll() }
        }
        .navigationTitle("Detail \(id)")
    }
}

#Preview { NavigationStack { Lesson03View() } }
