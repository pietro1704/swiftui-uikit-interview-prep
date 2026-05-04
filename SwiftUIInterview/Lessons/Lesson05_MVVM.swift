import SwiftUI
import Observation

// MARK: - Lesson 05 — @Observable + MVVM
//
// iOS 17+ introduces the `@Observable` macro, which replaces `ObservableObject`/`@Published`.
// Benefits: per-keypath tracking (a view re-renders only when the field it reads changes),
// less boilerplate.

@Observable
final class CounterViewModel {
    private(set) var count = 0
    private(set) var history: [Int] = []

    var canDecrement: Bool { count != 0 }

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
            goal: "Separate presentation logic from the view using @Observable.",
            exercise: """
            1. Add `undo()` to the ViewModel so it reverts the last increment.
            2. Write a test in SwiftUIInterviewTests that exercises `canDecrement`.
            3. Bonus: inject a `CounterStorage` protocol so state can be persisted.
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

                GroupBox("History") {
                    if vm.history.isEmpty {
                        Text("No actions yet").foregroundStyle(.secondary)
                    } else {
                        Text(vm.history.map(String.init).joined(separator: " → "))
                            .font(.callout.monospaced())
                    }
                }
            }

            SolutionDisclosure {
                CodeBlock("""
                // Add to CounterViewModel:
                var canUndo: Bool { !history.isEmpty }

                func undo() {
                    guard history.popLast() != nil else { return }
                    count = history.last ?? 0
                }

                // Test:
                func test_undo_revertsLastChange() {
                    let vm = CounterViewModel()
                    vm.increment(); vm.increment()
                    vm.undo()
                    XCTAssertEqual(vm.count, 1)
                }
                """)
            }
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview { NavigationStack { Lesson05View() } }
