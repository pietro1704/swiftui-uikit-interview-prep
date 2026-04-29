import SwiftUI
import Combine

// MARK: - Lesson 07 — Combine
//
// Even with async/await, Combine still appears everywhere in legacy apps:
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
            goal: "A reactive pipeline with debounce so we don't filter on every keystroke.",
            exercise: """
            1. Swap `debounce` for `throttle` and compare the behavior.
            2. Build a custom publisher that emits the query length.
            3. Bonus: combine two publishers (query + toggle) with `combineLatest`.
            """
        ) {
            TextField("Search", text: Binding(
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
