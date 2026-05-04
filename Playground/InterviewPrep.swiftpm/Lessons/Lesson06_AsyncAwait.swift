import SwiftUI

// MARK: - Lesson 06 — async/await + URLSession
//
// `.task { }` creates a Task tied to the view's lifecycle (auto-cancels on disappear).
// `URLSession.data(from:)` is the modern API returning `(Data, URLResponse)`.

struct Post: Decodable, Identifiable {
    let id: Int
    let title: String
    let body: String
}

@Observable
final class PostsViewModel {
    enum State { case idle, loading, loaded([Post]), failed(String) }
    private(set) var state: State = .idle

    func load() async {
        state = .loading
        do {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let posts = try JSONDecoder().decode([Post].self, from: data)
            state = .loaded(Array(posts.prefix(15)))
        } catch is CancellationError {
            // task cancelled: don't update state
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

struct Lesson06View: View {
    @State private var vm = PostsViewModel()

    var body: some View {
        LessonScaffold(
            title: "06 — async/await",
            goal: "Fetch data from an API and model idle/loading/loaded/failed.",
            exercise: """
            1. Add pull-to-refresh with `.refreshable { await vm.load() }`.
            2. Implement a `cancel()` that stores the Task handle so it can be cancelled.
            3. Bonus: parallelize two fetches using `async let`.
            """
        ) {
            Group {
                switch vm.state {
                case .idle:
                    Text("Tap Load")
                case .loading:
                    ProgressView("Loading...")
                case .loaded(let posts):
                    VStack(spacing: 8) {
                        ForEach(posts) { p in
                            VStack(alignment: .leading) {
                                Text(p.title).font(.headline)
                                Text(p.body).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                case .failed(let msg):
                    Label(msg, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity)

            Button("Load") {
                Task { await vm.load() }
            }
            .buttonStyle(.borderedProminent)
        }
        .task { await vm.load() }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview { NavigationStack { Lesson06View() } }
