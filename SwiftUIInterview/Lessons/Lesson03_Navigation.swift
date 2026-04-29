import SwiftUI

// MARK: - Lesson 03 — NavigationStack
//
// Replaces NavigationView (deprecated). Declarative push via:
//  - NavigationLink(value:) { label } + .navigationDestination(for:)
//  - NavigationStack(path:) for fully programmatic navigation

enum Route: Hashable {
    case detail(Int)
    case profile(String)
}

struct Lesson03View: View {
    @State private var path: [Route] = []

    var body: some View {
        LessonScaffold(
            title: "03 — Navigation",
            goal: "Type-safe navigation with full programmatic control over the path.",
            exercise: """
            1. Add a "Pop to root" button that empties `path`.
            2. Build a deep link: a single tap pushes detail(7) then profile("Ana").
            3. Use `.toolbar` to add a custom back button.
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

                Text("Current path depth: \(path.count)")
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
            Button("Go to profile") { path.append(.profile("User \(id)")) }
            Button("Pop to root") { path.removeAll() }
        }
        .navigationTitle("Detail \(id)")
    }
}

#Preview { NavigationStack { Lesson03View() } }
