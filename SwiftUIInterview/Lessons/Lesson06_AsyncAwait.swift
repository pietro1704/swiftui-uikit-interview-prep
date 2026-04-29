import SwiftUI

// MARK: - Lição 06 — async/await + URLSession
//
// `.task { }` cria uma Task atrelada ao lifecycle da view (cancela ao desaparecer).
// `URLSession.data(from:)` é a API moderna que retorna `(Data, URLResponse)`.

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
            // task cancelada: não atualiza state
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
            goal: "Buscar dados de API e modelar idle/loading/loaded/failed.",
            exercise: """
            1. Adicione pull-to-refresh com `.refreshable { await vm.load() }`.
            2. Implemente `cancel()` que dispara `Task` e armazena handle p/ cancelar.
            3. Bônus: paralelize 2 fetches usando `async let`.
            """
        ) {
            Group {
                switch vm.state {
                case .idle:
                    Text("Toque em Carregar")
                case .loading:
                    ProgressView("Carregando...")
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

            Button("Carregar") {
                Task { await vm.load() }
            }
            .buttonStyle(.borderedProminent)
        }
        .task { await vm.load() }
    }
}

#Preview { NavigationStack { Lesson06View() } }
