import SwiftUI
import Observation

// MARK: - Lição 05 — @Observable + MVVM
//
// iOS 17+ trouxe a macro `@Observable` que substitui ObservableObject/@Published.
// Vantagens: granularidade fina (re-render apenas no campo lido), menos boilerplate.

@Observable
final class CounterViewModel {
    private(set) var count = 0
    private(set) var history: [Int] = []

    var canDecrement: Bool { count > 0 }

    func increment() {
        count += 1
        history.append(count)
    }
    func decrement() {
        guard canDecrement else { return }
        count -= 1
        history.append(count)
    }
    func reset() {
        count = 0
        history.removeAll()
    }
}

struct Lesson05View: View {
    @State private var vm = CounterViewModel()

    var body: some View {
        LessonScaffold(
            title: "05 — MVVM",
            goal: "Separar lógica de apresentação usando @Observable.",
            exercise: """
            1. Adicione `undo()` ao ViewModel que reverte o último incremento.
            2. Escreva um teste em SwiftUIInterviewTests que valida `canDecrement`.
            3. Bônus: injete um protocolo `CounterStorage` para persistir state.
            """
        ) {
            VStack(spacing: 12) {
                Text("\(vm.count)").font(.system(size: 64, weight: .bold)).monospacedDigit()
                HStack {
                    Button("−", action: vm.decrement).disabled(!vm.canDecrement)
                    Button("+", action: vm.increment)
                    Button("Reset", action: vm.reset)
                }
                .buttonStyle(.borderedProminent)

                GroupBox("Histórico") {
                    if vm.history.isEmpty {
                        Text("Sem ações ainda").foregroundStyle(.secondary)
                    } else {
                        Text(vm.history.map(String.init).joined(separator: " → "))
                            .font(.callout.monospaced())
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { Lesson05View() } }
