/*:
 # 01 — SwiftUI Fundamentals (livecoding drills)

 You said you've never used SwiftUI in production. This page builds the
 mental model from zero so you can reason out loud during a livecoding round.

 In a senior LATAM staffing interview, expect prompts like:
 - "Build a counter view; now extract a reusable child" (state ownership).
 - "Why doesn't this list animate?" (identity).
 - "Refactor this UIKit ViewController as SwiftUI" (state flow).

 Each drill below has:
 1. **Prompt** — what you'd be asked to produce.
 2. **Skeleton** — empty signature you fill in.
 3. **Talk-track** — sentences to say while typing (interviewers reward this).
 4. **Solution** — at the bottom, in a `/* … */` block. Don't peek.

 ----
 ## Mental model — read first

 SwiftUI views are **value types describing the UI**, not the UI itself.
 SwiftUI calls `body` whenever the view's input changes; the framework
 diffs the resulting tree and updates the screen.

 Three property wrappers cover 95% of state:

 - `@State` — local source of truth, owned by the view.
 - `@Binding` — a two-way handle to state owned somewhere else.
 - `@Observable` (iOS 17+) — class-based, for shared models / VMs.

 Identity rule: SwiftUI keeps `@State` alive as long as the view's
 *position + type + explicit .id()* match across body re-evaluations.
 Change any of those and `@State` resets.

 ----
 */
import SwiftUI

// MARK: - Drill 1: Counter with extracted child

/*:
 ### Prompt 1
 Build a `CounterView` showing a number and `+` / `-` buttons. Then
 extract a `StepperRow` subview that takes a `@Binding<Int>` and renders
 the buttons. Parent owns state, child only mutates it.

 **Talk-track** (say while typing):
 > "Parent owns `@State count`, passes `$count` as `@Binding` to the
 > child. The child mutates via `value -= 1`; SwiftUI propagates the
 > change up automatically because Binding is a two-way reference."

 Fill in the TODO blocks below.
 */

struct StepperRow: View {
    // TODO: declare a Binding<Int> property
    var body: some View {
        HStack {
            // TODO: − button decrements value
            // TODO: + button increments value
            Text("placeholder")
        }
    }
}

struct CounterView: View {
    // TODO: declare local state for count, defaulting to 0
    var body: some View {
        VStack {
            // TODO: show count.description as a Text
            // TODO: embed StepperRow, passing the binding
            Text("placeholder")
        }
    }
}

// MARK: - Drill 2: Why doesn't this list animate?

/*:
 ### Prompt 2 — debug
 The list below visibly "jumps" instead of animating row insertions.
 The interviewer asks: **why?** Fix it without rewriting the data model.

 **Hint:** look at the `id:` parameter on `ForEach`.
 */

struct Fruit {
    var name: String
    var emoji: String
}

struct FruitList: View {
    @State private var fruits: [Fruit] = [
        .init(name: "Mango", emoji: "🥭"),
        .init(name: "Apple", emoji: "🍎"),
    ]
    var body: some View {
        List {
            // BUG: identity churns when items mutate. Why?
            ForEach(fruits, id: \.name) { fruit in
                Text("\(fruit.emoji) \(fruit.name)")
            }
            Button("Add Grape") {
                withAnimation { fruits.append(.init(name: "Grape", emoji: "🍇")) }
            }
        }
    }
}

// MARK: - Drill 3: Convert this UIKit thinking to SwiftUI

/*:
 ### Prompt 3
 An interviewer pastes pseudo-UIKit:
 ```
 // viewModel has @Published var query: String
 // textField.delegate = self
 // func textField(...didChange...) { viewModel.query = text }
 // viewModel.$query.sink { results in self.tableView.reloadData() }
 ```
 Re-express as a SwiftUI view. No Combine. Use `@Observable` macro.

 **Talk-track**: "In SwiftUI, the binding `$vm.query` is a *two-way handle*
 to the property — typing into the TextField writes through, and the body
 re-evaluates whenever an `@Observable` keypath I read changes."
 */

import Observation

// TODO: model with @Observable (NOT ObservableObject)
final class SearchVM_Empty {
    var query = ""
    var results: [String] { ["one", "two", "three"].filter { $0.hasPrefix(query) } }
}

struct SearchView_Empty: View {
    // TODO: own a SearchVM as @State
    var body: some View {
        VStack {
            // TODO: TextField bound to vm.query
            // TODO: List of vm.results
            Text("placeholder")
        }
    }
}

/*:
 ----
 ## When you're ready, scroll past the line below for the reference solutions.
 */

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1 -----
 struct StepperRow: View {
     @Binding var value: Int
     var body: some View {
         HStack {
             Button("−") { value -= 1 }
             Text("\(value)").font(.title2).monospacedDigit().frame(minWidth: 40)
             Button("+") { value += 1 }
         }
         .buttonStyle(.bordered)
     }
 }
 struct CounterView: View {
     @State private var count = 0
     var body: some View {
         VStack(spacing: 16) {
             Text("\(count)").font(.system(size: 60, weight: .bold))
             StepperRow(value: $count)
         }
     }
 }
 // Talk-track addendum: "I could have passed a closure (count: Int, onChange: (Int) -> Void)
 //  but Binding is more idiomatic and the parent doesn't have to forward
 //  every event by hand."

 // ----- Drill 2 -----
 // Bug: `id: \.name` keys identity by a value that ALSO acts as the
 // displayed content. If the user renames a fruit, identity changes and
 // SwiftUI tears down the row instead of updating it. Worse: if two fruits
 // had the same name, identity would collide.
 //
 // Fix: give Fruit a stable `Identifiable` id (UUID), use ForEach(fruits).
 //
 // struct Fruit: Identifiable { let id = UUID(); var name: String; var emoji: String }
 // ForEach(fruits) { fruit in Text("\(fruit.emoji) \(fruit.name)") }
 //
 // Senior framing: "SwiftUI's diffing is identity-driven. Anything that
 //  varies with content is a bad identity choice — the rule is *stable +
 //  unique*, like a database primary key."

 // ----- Drill 3 -----
 @Observable
 final class SearchVM {
     var query = ""
     private let dataset = ["Swift", "SwiftUI", "Combine", "Concurrency"]
     var results: [String] {
         query.isEmpty ? dataset : dataset.filter { $0.localizedCaseInsensitiveContains(query) }
     }
 }
 struct SearchView: View {
     @State private var vm = SearchVM()    // @State OWNS the @Observable instance
     var body: some View {
         VStack {
             TextField("Search", text: $vm.query)   // Bindable via $vm.query
                 .textFieldStyle(.roundedBorder)
             List(vm.results, id: \.self) { Text($0) }
         }
     }
 }
 // Three things to call out aloud:
 //  - @State on @Observable is the Apple-blessed pattern (vs old @StateObject).
 //  - $vm.query works because @Observable conforms to Bindable.
 //  - body re-runs only when the keypaths it reads (query, results)
 //    actually change — fine-grained, unlike ObservableObject.

*/
