/*:
 # 01 — SwiftUI Fundamentals (livecoding drills)

 Builds the SwiftUI mental model from zero so you can reason out loud
 during a livecoding round. Useful even after years of UIKit — the
 declarative paradigm flips a lot of intuitions.

 ## How to use this page

 Each drill below has:
 1. **Prompt** — what you'd be asked to produce.
 2. **Skeleton** — empty signature you fill in.
 3. **Talk-track** — sentences to say while typing.
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
import Observation

// MARK: - Drill 1: Counter with extracted child

/*:
 ### Prompt 1 — from-scratch
 Build a `CounterView` showing a number and `+` / `-` buttons. Then
 extract a `StepperRow` subview that takes a `@Binding<Int>` and renders
 the buttons. Parent owns state, child only mutates it.

 **Talk-track**:
 > "Parent owns `@State count`, passes `$count` as `@Binding` to the
 > child. The child mutates via `value -= 1`; SwiftUI propagates the
 > change up automatically because Binding is a two-way reference."
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
 ### Prompt 2 — bug-hunt
 The list below visibly "jumps" instead of animating row insertions.
 The interviewer asks: **why?** Fix without rewriting the data model.

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
 ### Prompt 3 — port
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

// MARK: - Drill 4: .task vs .onAppear

/*:
 ### Prompt 4 — bug-hunt
 The view below leaks: dismissing it mid-load still hits `posts = ...` after
 the network completes. Pick the right SwiftUI modifier so the load is
 cancelled when the view disappears.
 */

struct FeedView_Buggy: View {
    @State private var posts: [String] = []
    var body: some View {
        List(posts, id: \.self) { Text($0) }
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    posts = ["fetched"]   // <- mutation may run after dismiss
                }
            }
    }
}

// TODO: rewrite to use `.task { ... }` so dismiss cancels the fetch.

// MARK: - Drill 5: @Bindable for child editing parent's @Observable

/*:
 ### Prompt 5 — bug-hunt
 The child view can't compile `$user.name`. Fix it without removing the
 `@Observable` model.
 */

@Observable
final class User_05 {
    var name = ""
    var email = ""
}

struct EditUserView_Buggy: View {
    let user: User_05            // ❌ no $ available
    var body: some View {
        Form {
            TextField("Name", text: $user.name)   // won't compile
        }
    }
}

// TODO: change the property declaration so $user.name works.

// MARK: - Drill 6: List with sections

/*:
 ### Prompt 6 — from-scratch
 Render the `groups` data below as a sectioned `List` — section title +
 items per section.
 */

struct Group_06 {
    let title: String
    let items: [String]
}

let groups_06: [Group_06] = [
    .init(title: "Fruits", items: ["Apple", "Mango"]),
    .init(title: "Veggies", items: ["Kale", "Carrot"]),
]

struct GroupedList_Empty: View {
    var body: some View {
        // TODO: List with one Section per group
        List { Text("placeholder") }
    }
}

// MARK: - Drill 7: Environment value vs Environment(MyType.self)

/*:
 ### Prompt 7 — port
 Old (pre-iOS 17) code uses `@EnvironmentObject` + `ObservableObject`. \
 Migrate to the iOS 17+ `@Observable` + `@Environment(_)` style.
 */

final class Theme_OLD: ObservableObject {
    @Published var color: Color = .blue
}

struct DeepView_OLD: View {
    @EnvironmentObject var theme: Theme_OLD
    var body: some View {
        Text("hi").foregroundStyle(theme.color)
    }
}

// TODO: migrate Theme_OLD to @Observable; migrate DeepView_OLD to use
// @Environment(Theme.self).

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

 // ----- Drill 2 -----
 // Bug: id: \.name uses content as identity. Renaming a fruit churns
 // identity → SwiftUI tears down the row instead of updating it.
 // Fix: stable id (UUID), use ForEach(fruits) with Identifiable.
 //
 // struct Fruit: Identifiable { let id = UUID(); var name: String; var emoji: String }
 // ForEach(fruits) { fruit in Text("\(fruit.emoji) \(fruit.name)") }

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
     @State private var vm = SearchVM()
     var body: some View {
         VStack {
             TextField("Search", text: $vm.query)
                 .textFieldStyle(.roundedBorder)
             List(vm.results, id: \.self) { Text($0) }
         }
     }
 }

 // ----- Drill 4 -----
 struct FeedView: View {
     @State private var posts: [String] = []
     var body: some View {
         List(posts, id: \.self) { Text($0) }
             .task {                                 // tied to view lifetime
                 try? await Task.sleep(for: .seconds(2))
                 posts = ["fetched"]
             }
     }
 }
 // .task auto-cancels when view disappears; .onAppear { Task {} } does NOT.

 // ----- Drill 5 -----
 struct EditUserView: View {
     @Bindable var user: User_05      // unlocks $user.name etc.
     var body: some View {
         Form {
             TextField("Name", text: $user.name)
             TextField("Email", text: $user.email)
         }
     }
 }
 // Senior framing: "Bindable lets a child view that received an @Observable
 //  by value still get bindings to its properties — replaces the old
 //  ObservedObject-passing-via-Binding pattern."

 // ----- Drill 6 -----
 List {
     ForEach(groups_06, id: \.title) { group in
         Section(group.title) {
             ForEach(group.items, id: \.self) { Text($0) }
         }
     }
 }

 // ----- Drill 7 -----
 @Observable
 final class Theme {
     var color: Color = .blue
 }
 struct DeepView: View {
     @Environment(Theme.self) private var theme
     var body: some View {
         Text("hi").foregroundStyle(theme.color)
     }
 }
 // App entry:
 //   @State private var theme = Theme()
 //   ContentView().environment(theme)

*/
