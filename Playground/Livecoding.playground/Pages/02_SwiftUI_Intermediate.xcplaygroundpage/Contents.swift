// Page 02 — SwiftUI Intermediate
// Read prompts/explanations: ../../../../docs/livecoding/02-swiftui-intermediate.md
//
// Reordered by interview probability (LATAM senior livecoding):
//   high   1. State ownership          (@State / @Bindable / @Observable)
//   high   2. View identity            (.id() — bug-hunt)
//   high   3. MVVM navigation          (data-driven, navigationDestination)
//   high   4. NavigationStack(path:)   (deep link — bug-hunt)
//   high   5. Environment DI           (no prop-drilling)
//   med    6. PreferenceKey            (child→parent)
//   med    7. @FocusState              (login form focus chain)
//   med    8. ViewModifier             (.roundedShadow)
//
// LOW priority (Custom Layout, AnyLayout) → see page 02b.
//
// REVIEW CHECKPOINT at the bottom — speak each answer aloud before peeking.

import SwiftUI
import Observation
import PlaygroundSupport

// MARK: - Live preview
// Run the playground (▶), then Editor → Live View (⌥⌘↵).
// Swap the argument to setLiveView(...) to demo any other drill.

PlaygroundPage.current.setLiveView(
    Page2Exercise5View()
        .frame(width: 420, height: 600)
)

// =============================================================================
// MARK: - Drill 1 — State ownership: shared mutable state across siblings  (high)
// =============================================================================
//
// Scenario: CheckoutScreen (root) with two siblings — CartView (list with
// +/- buttons per row) and CheckoutBar (live total + Pay button that
// empties the cart).
//
// Acceptance:
// - Single source of truth, no stale copies.
// - @Observable only — no ObservableObject / @StateObject / @ObservedObject.
// - Mutating qty in CartView updates total in CheckoutBar in the same frame.
// - Pay clears the cart.
// - Trap: @Observable does NOT auto-give you $-bindings. Use @Bindable in
//   the body of any view that needs to project bindings to children.
//
// Talk-track: "Owner is the parent with @State. Children receive the VM
// by init and declare @Bindable internally when they need $. ObservableObject
// did this automatically via @Published, but @Observable separated storage
// (@State) from binding-projection (@Bindable)."

@Observable
final class CartVM {
    struct CartItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let price: Decimal
        var qty: Int
    }
    var items: [CartItem] = [
        .init(name: "Coffee", price: 5, qty: 1),
        .init(name: "Bagel", price: 7, qty: 2),
        .init(name: "Juice", price: 6, qty: 1),
    ]
    var total: Decimal {
        items.reduce(Decimal(0)) { $0 + $1.price * Decimal($1.qty) }
    }
    func increment(_ id: CartItem.ID) {
        if let i = items.firstIndex(where: { $0.id == id }) { items[i].qty += 1 }
    }
    func decrement(_ id: CartItem.ID) {
        if let i = items.firstIndex(where: { $0.id == id }), items[i].qty > 0 {
            items[i].qty -= 1
        }
    }
    func clear() { items.removeAll() }
}

// TODO: build CheckoutScreen, CartView, CheckoutBar
struct Page2Exercise1View: View {
    @State private var vm = CartVM()
    var body: some View {
        // TODO
        Text("placeholder — implement CheckoutScreen")
    }
}

// =============================================================================
// MARK: - Drill 2 — View identity surprise (.id)  (high)  (bug-hunt)
// =============================================================================
//
// Run Page2Exercise2Experiment in the live view. Toggle "Use .id()":
// - OFF: type in the TextField, tap "Switch user" → note PERSISTS (stale).
// - ON:  type in the TextField, tap "Switch user" → note RESETS (remount).
// .id(value) forces a new identity when `value` changes → @State recreates.

struct Page2Exercise2View: View {
    let userId: UUID
    @State private var note: String = ""
    var body: some View {
        VStack(spacing: 12) {
            Text("User: \(userId.uuidString.prefix(8))").font(.headline)
            TextField("Notes for this user", text: $note)
                .textFieldStyle(.roundedBorder)
            Text("current note: '\(note)'")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.yellow.opacity(0.2))
    }
}

struct Page2Exercise2Experiment: View {
    @State private var userId = UUID()
    @State private var useID = false
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Switch user") { userId = UUID() }
                    .buttonStyle(.borderedProminent)
                Toggle("Use .id()", isOn: $useID)
            }
            .padding(.horizontal)
            if useID {
                Page2Exercise2View(userId: userId).id(userId)
            } else {
                Page2Exercise2View(userId: userId)
            }
            Text("userId: \(userId.uuidString.prefix(8))  ·  useID: \(useID ? "ON" : "OFF")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// =============================================================================
// MARK: - Drill 3 — Data-driven navigation in MVVM  (high)  (from-scratch)
// =============================================================================
//
// "In MVVM SwiftUI, where does navigation state live?" → in the VM, not in
// @State on the View. Build list + detail with navigationDestination(item:).
//
// Trap: @Observable does not give $-bindings → use @Bindable in body.

struct Post: Identifiable, Hashable {
    let id = UUID()
    let title: String
}

@Observable
final class FeedVM {
    var posts: [Post] = [.init(title: "Hello"), .init(title: "World")]
    var selectedPost: Post?
}

struct Page2Exercise3View: View {
    @State private var vm = FeedVM()
    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            List(vm.posts) { post in
                Button(post.title) { vm.selectedPost = post }
            }
            .navigationDestination(item: $vm.selectedPost) { post in
                Text("Detail: \(post.title)")
            }
        }
    }
}

// Alias kept so the existing setLiveView reference still compiles.
typealias Page2Exercise5View = Page2Exercise3View

// =============================================================================
// MARK: - Drill 4 — NavigationStack(path:) deep link  (high)  (bug-hunt)
// =============================================================================
//
// The deep link silently does nothing — `path.append` doesn't push anything.
// Why? What's missing on NavigationStack to make typed routes work?
//
// Hint: NavigationStack(path:) bound to a typed path needs ONE more modifier
// inside the stack to know how to render each route value.

enum Route04: Hashable { case detail(Int); case profile(String) }

struct Page2Exercise4View: View {
    @State private var path = NavigationPath()
    var body: some View {
        NavigationStack(path: $path) {
            Button("Deep link") {
                path.append(Route04.detail(7))
                path.append(Route04.profile("Ana"))
            }
            // BUG: missing .navigationDestination(for: Route04.self) { ... }
        }
    }
}

// =============================================================================
// MARK: - Drill 5 — Environment DI (no prop-drilling)  (high)  (from-scratch)
// =============================================================================
//
// APIClient is used by 5 nested views. No singleton, no prop-drilling.
//
// Talk-track: "EnvironmentKey with default, property on EnvironmentValues,
// inject at the top via .environment(\.api, ...), read deep with @Environment.
// Tests/previews override per call-site."

protocol APIClient: Sendable {
    func fetch() async throws -> [String]
}

struct LiveAPI: APIClient {
    func fetch() async throws -> [String] { ["Apple", "Banana", "pips"] }
}

struct APIClientKey: EnvironmentKey {
    static let defaultValue: any APIClient = LiveAPI()
}

extension EnvironmentValues {
    var api: any APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

struct Page2Exercise5View_DI: View {
    @Environment(\.api) private var api
    @State private var items: [String] = []
    var body: some View {
        List(items, id: \.self) { Text($0) }
            .task { items = (try? await api.fetch()) ?? [] }
    }
}

// =============================================================================
// MARK: - Drill 6 — PreferenceKey (child → parent)  (med)  (from-scratch)
// =============================================================================
//
// Data-flow direction:
// - Environment: parent → child (top-down).
// - PreferenceKey: child → parent (bottom-up).
//
// Child writes via .preference(key:value:); ancestor reads via
// .onPreferenceChange. reduce() combines values when multiple descendants
// publish on the same key.

struct HeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct Page2Exercise6View: View {
    @State private var measuredHeight: CGFloat = 0
    @State private var label: String = "Tap to grow / shrink"
    var body: some View {
        VStack(spacing: 12) {
            Text("Parent measured: \(Int(measuredHeight)) pt")
                .font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 12) {
                Text(label)
                    .padding()
                    .background(.yellow.opacity(0.4))
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: HeightKey.self, value: proxy.size.height)
                        }
                    )
                    .onTapGesture {
                        label = label.count > 30
                            ? "Short"
                            : "A much longer label that wraps onto multiple lines so the height visibly changes"
                    }
                Color.red.frame(width: 80, height: measuredHeight)
            }
        }
        .padding()
        .onPreferenceChange(HeightKey.self) { measuredHeight = $0 }
    }
}

// =============================================================================
// MARK: - Drill 7 — @FocusState (login form focus chain)  (med)  (from-scratch)
// =============================================================================
//
// LoginForm: user + pass fields. On appear, focus user. Submit on user →
// focus pass. Submit on pass → dismiss focus (close keyboard).
//
// TODO: enum Field { case user, pass }
// TODO: @FocusState private var focused: Field?
// TODO: .focused($focused, equals: .user) on each field.
// TODO: .submitLabel(.next) / .submitLabel(.go).
// TODO: .onAppear { focused = .user }
// TODO: .onSubmit { focused = focused == .user ? .pass : nil }

struct Page2Exercise7View: View {
    @State private var user = ""
    @State private var pass = ""
    var body: some View {
        Form {
            TextField("User", text: $user)
            SecureField("Pass", text: $pass)
        }
    }
}

// =============================================================================
// MARK: - Drill 8 — Reusable ViewModifier (.roundedShadow)  (med)  (from-scratch)
// =============================================================================
//
// .roundedShadow(radius: 8, corner: 12) — a composable modifier.
// 1) struct RoundedShadowStyle: ViewModifier.
// 2) extension View with an ergonomic function.

struct RoundedShadowStyle: ViewModifier {
    var radius: CGFloat = 6
    var corner: CGFloat = 10
    func body(content: Content) -> some View {
        content
            .background(.background, in: RoundedRectangle(cornerRadius: corner))
            .shadow(radius: radius)
    }
}

extension View {
    func roundedShadow(radius: CGFloat = 6, corner: CGFloat = 10) -> some View {
        modifier(RoundedShadowStyle(radius: radius, corner: corner))
    }
}

// =============================================================================
// MARK: - REVIEW CHECKPOINT — speak each answer aloud, then peek
// =============================================================================
//
// State ownership
// 1. Difference between @State and @Bindable. When to use each?
// 2. Why does @Observable require @Bindable to project $bindings, while
//    ObservableObject did not?
// 3. Where does the source of truth live when two siblings share state?
//
// View identity
// 4. What does .id(value) do to the tree when value changes?
// 5. Why can a child's @State go stale without .id()?
// 6. How is it different from structural identity (if/else, ForEach)?
//
// Navigation
// 7. In MVVM, why does the selection live in the VM and not as @State on
//    the View?
// 8. Difference between navigationDestination(for:) and (item:)?
// 9. NavigationStack(path:) without .navigationDestination(for:) → what
//    happens?
//
// Environment
// 10. When to use Environment vs init injection?
// 11. How do you override an EnvironmentKey just for preview/test?
//
// PreferenceKey
// 12. Data direction in Environment vs PreferenceKey?
// 13. What does `reduce` do when multiple children publish?
// 14. Why does GeometryReader go inside .background, not as a wrapper?
//
// Focus
// 15. Why does @FocusState use an optional enum as its type?
// 16. How do you dismiss the keyboard programmatically?
//
// Modifier
// 17. When ViewModifier vs an extension on View returning some View?
//
// ============================================================================
// ANSWERS — only peek AFTER trying to verbalize
// ============================================================================
/*
1. @State is owner (creates storage, holds lifetime). @Bindable is a lens
   over an existing @Observable, used to project $bindings. @State on the
   owner; @Bindable wherever you need $.
2. ObservableObject + @Published produced bindings via the wrapper's
   projectedValue. @Observable is a macro that does not generate $;
   @Bindable supplies it from the call site.
3. At the lowest common ancestor of the two siblings. Create @State there;
   pass it via init to children (which declare @Bindable if they need $).
4. Forces a new logical identity → SwiftUI tears down and remounts the
   subtree → @State recreates from scratch. Without .id, same position
   and type means SwiftUI keeps @State across re-renders.
5. SwiftUI matches @State by (type, position in tree). If the parent
   passes new data but the slot is the same, @State persists — possibly
   stale relative to the data.
6. Structural: if/else and ForEach already create new identities when the
   branch or key changes. .id() is the manual override for "same place,
   but logically a different thing".
7. Navigation is part of the feature's state, not the view's. It survives
   parent re-renders, is testable outside the UI, keeps MVVM clean.
8. (for:) → router-style, matches by TYPE via NavigationPath / a typed
   array. (item:) → shows detail while Binding<Item?> is non-nil. For
   MVVM with a single current selection, (item:) is cleaner.
9. The buttons appear, but appending to the path doesn't push anything —
   you didn't declare how to render each Route. Silent dead-end.
10. Environment when many descendants need the same resource and prop-
    drilling pollutes. Init injection when only ONE consumer needs it.
11. .environment(\.api, MockAPI()) on the PreviewProvider or in the test
    before instantiating the view.
12. Environment goes down. PreferenceKey goes up.
13. SwiftUI aggregates values published by descendants in tree order;
    reduce defines the combine rule (max, sum, append, etc).
14. GeometryReader as a wrapper EATS the proposed space (it proposes
    infinity to its child and takes everything from the parent). Inside
    .background(GeometryReader…) it inherits the outer view's size
    without affecting layout.
15. Optional to represent "nothing focused". Enum to discriminate fields
    type-safely (no magic strings).
16. focused = nil (or hideKeyboard via UIApplication, but the native way
    is to clear the FocusState).
17. Use ViewModifier when the modifier has internal state, multiple
    parameters, or complex composition. A plain extension is fine for
    aliases. In an interview, always show BOTH PIECES — struct +
    extension.
*/
