import SwiftUI
import Combine

// MARK: - Lição 07 — Combine
//
// Mesmo com async/await, Combine ainda é onipresente em apps legados:
// publishers, operators (debounce, map, removeDuplicates), sinks.

@Observable
final class SearchViewModel {
    var query = "" {
        didSet { querySubject.send(query) }
    }
    private(set) var results: [String] = []

    private let querySubject = PassthroughSubject<String, Never>()
    private var bag = Set<AnyCancellable>()
    private let dataset = ["Swift", "SwiftUI", "Combine", "UIKit", "Concurrency",
                            "Actors", "Async", "Await", "Task", "MainActor"]

    init() {
        querySubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [dataset] q -> [String] in
                guard !q.isEmpty else { return dataset }
                return dataset.filter { $0.localizedCaseInsensitiveContains(q) }
            }
            .sink { [weak self] in self?.results = $0 }
            .store(in: &bag)

        results = dataset
    }
}

struct Lesson07View: View {
    @State private var vm = SearchViewModel()

    var body: some View {
        LessonScaffold(
            title: "07 — Combine",
            goal: "Pipeline reativo com debounce p/ não filtrar a cada tecla.",
            exercise: """
            1. Adicione `.throttle` em vez de debounce e compare o comportamento.
            2. Implemente um publisher custom que emite o tamanho da query.
            3. Bônus: combine 2 publishers (query + toggle) com `combineLatest`.
            """
        ) {
            TextField("Buscar", text: Binding(
                get: { vm.query },
                set: { vm.query = $0 }
            ))
            .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(vm.results, id: \.self) { item in
                    Text(item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

#Preview { NavigationStack { Lesson07View() } }
