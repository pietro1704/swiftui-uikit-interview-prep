// Page 01 — SwiftUI Fundamentals
// Read prompts/explanations: ../../../../docs/livecoding/01-swiftui-fundamentals.md
// (or open docs/livecoding/01-swiftui-fundamentals.md in any markdown viewer)

import SwiftUI
import Observation

// MARK: Drill 1 — Counter with extracted child

struct StepperRow: View {
    // TODO: declare a Binding<Int> property
    @Binding var value: Int
    var body: some View {
        HStack {
            Button("−") { value -= 1 }
            Text("\(value)")
            Button("+") { value += 1 }
            // TODO: − button decrements value
            // TODO: + button increments value
        }
    }
}

struct Page1Exercise1View: View {
    // TODO: declare local state for count, defaulting to 0
    var count = 0
    var body: some View {
        VStack {
            // TODO: show count.description as a Text
            Text("count")
            // TODO: embed StepperRow, passing the binding
            StepperRow(value: $count)
            Text("placeholder")
        }
    }
}

// MARK: Drill 2 — Why doesn't this list animate? (bug-hunt — fix `id:`)

struct Fruit {
    var name: String
    var emoji: String
}

struct Page1Exercise2View: View {
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

// MARK: Drill 3 — Convert UIKit thinking to SwiftUI

final class SearchVM_Empty {
    var query = ""
    var results: [String] { ["one", "two", "three"].filter { $0.hasPrefix(query) } }
}

struct Page1Exercise3View: View {
    // TODO: own a SearchVM as @State
    var body: some View {
        VStack {
            // TODO: TextField bound to vm.query
            // TODO: List of vm.results
            Text("placeholder")
        }
    }
}

// MARK: Drill 4 — `.task` vs `.onAppear` (bug-hunt — fix the leak)

struct Page1Exercise4View: View {
    @State private var posts: [String] = []
    var body: some View {
        List(posts, id: \.self) { Text($0) }
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    posts = ["fetched"]   // mutation may run after dismiss
                }
            }
    }
}

// MARK: Drill 5 — @Bindable for child editing parent's @Observable

@Observable
final class User_05 {
    var name = ""
    var email = ""
}

struct Page1Exercise5View: View {
    let user: User_05            // ❌ no $ available — fix the property declaration
    var body: some View {
        Form {
//            TextField("Name", text: $user.name)   // won't compile
        }
    }
}

// MARK: Drill 6 — List with sections

struct Group_06 {
    let title: String
    let items: [String]
}

let groups_06: [Group_06] = [
    .init(title: "Fruits", items: ["Apple", "Mango"]),
    .init(title: "Veggies", items: ["Kale", "Carrot"]),
]

struct Page1Exercise6View: View {
    var body: some View {
        // TODO: List with one Section per group
        List { Text("placeholder") }
    }
}

// MARK: Drill 7 — EnvironmentObject → @Environment(_) migration

final class Theme_OLD: ObservableObject {
    @Published var color: Color = .blue
}

struct Page1Exercise7View: View {
    @EnvironmentObject var theme: Theme_OLD
    var body: some View {
        Text("hi").foregroundStyle(theme.color)
    }
}
// TODO: migrate Theme_OLD to @Observable; migrate DeepView_OLD to @Environment(Theme.self).

// MARK: - Live preview
// Run the playground (▶ in the bottom-left), then Editor → Live View (⌥⌘↵).
// Change the argument to setLiveView(...) to demo any other drill:
//   Page1Exercise2View(), Page1Exercise3View(), etc.

import PlaygroundSupport

PlaygroundPage.current.setLiveView(
    Page1Exercise1View()
        .frame(width: 320, height: 240)
)

/*

================================================================================
SOLUTIONS
================================================================================

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
struct Page1Exercise1View: View {
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
// Bindable lets a child view that received an @Observable by value still
// get bindings to its properties — replaces the old ObservedObject pattern.

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
