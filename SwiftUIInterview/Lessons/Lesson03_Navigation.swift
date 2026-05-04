import SwiftUI

// MARK: - Lesson 03 — NavigationStack
//
// Replaces NavigationView (deprecated). Declarative push via:
//  - NavigationLink(value:) { label } + .navigationDestination(for:)
//  - NavigationStack(path:) for fully programmatic navigation
//
// This lesson piggybacks on the root NavigationStack owned by ContentView
// (a nested NavigationStack pushed from another stack pops itself instantly
// on iOS, which is why the lesson row used to bounce back to the list).
// The shared `NavigationPath` is threaded down via @Binding so the
// programmatic `path.append(...)` / `path = ...` exercises still work.

enum Route: Hashable {
    case detail(Int)
    case profile(String)
    case root
}

struct Lesson03RootContent: View {
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            ForEach(1...3, id: \.self) { i in
                Button("Push detail \(i)") { path.append(Route.detail(i)) }
                    .buttonStyle(.bordered)
            }
            Button("Deep link → detail(7) → profile(Ana)") {
                path.append(Route.detail(7))
                path.append(Route.profile("Ana"))
            }
            .buttonStyle(.borderedProminent)
            Button("Push root onto stack") { path.append(Route.root) }
                .buttonStyle(.bordered)
            Button("Pop to root") { path = NavigationPath() }

            Text("Current path depth: \(path.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Root")
    }
}

struct Lesson03View: View {
    @Binding var path: NavigationPath

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
            Lesson03RootContent(path: $path)
        }
    }
}

struct Lesson03DetailView: View {
    let id: Int
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Detail #\(id)").font(.largeTitle)
            Button("Go to profile") { path.append(Route.profile("User \(id)")) }
            Button("Push detail \(id + 1)") { path.append(Route.detail(id + 1)) }
            Button("Pop to root") { path = NavigationPath() }
            Button("Push root onto stack") { path.append(Route.root) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Detail \(id)")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Label("Voltar", systemImage: "chevron.left")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    return NavigationStack(path: $path) {
        Lesson03View(path: $path)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .detail(let id):
                    Lesson03DetailView(id: id, path: $path)
                case .profile(let name):
                    Text("Profile: \(name)").font(.title)
                case .root:
                    Lesson03RootContent(path: $path)
                }
            }
    }
}
