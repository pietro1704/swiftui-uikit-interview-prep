/*:
 # 02 — SwiftUI Intermediate

 Once Page 01 is comfortable, these are the second-round drills:
 environment-based DI, identity tricks, view modifiers, preference keys,
 navigation as data, custom Layout, focus.

 ----
 */
import SwiftUI
import Observation

/*:
 ## Drill 1 — Inject a dependency without prop-drilling
 */

/*:
 ### Prompt 1 — from-scratch
 You have an `APIClient` protocol used by 5 nested views. The interviewer
 says: "I don't want a singleton, and I don't want to thread the client
 through every initializer. How would you do it in SwiftUI?"

 **Talk-track**: "SwiftUI's Environment is the canonical answer: define an
 EnvironmentKey with a default, expose a property on EnvironmentValues,
 inject at the top with .environment(\\.apiClient, ...), read deep with
 @Environment. Tests/previews override per-call site."
 */

protocol APIClient {
    func fetch() async throws -> [String]
}

struct LiveAPI: APIClient {
    func fetch() async throws -> [String] { ["Apple", "Banana"] }
}

/*:
 TODO: 1) define a private EnvironmentKey for APIClient
 TODO: 2) extension EnvironmentValues with `var api: any APIClient`
 */

struct DeepFeedView: View {
    // TODO: read the API client from the environment
    var body: some View {
        // TODO: load on .task and display results
        Text("placeholder")
    }
}

/*:
 ## Drill 2 — View identity surprise
 */

/*:
 ### Prompt 2 — bug-hunt
 The detail screen below loses its scroll position whenever the user
 picks a different item from a menu. Why, and what's the one-liner fix?
 */

struct ProfileView: View {
    let userId: UUID
    @State private var scrollPos: CGFloat = 0
    var body: some View {
        ScrollView { Text("User: \(userId.uuidString.prefix(8))") }
        // ☝️ Identity stability across userId changes — what's happening?
    }
}

/*:
 ## Drill 3 — Reusable modifier with parameters
 */

/*:
 ### Prompt 3 — from-scratch
 Build a modifier `roundedShadow(radius:corner:)` so any view can call
 `.roundedShadow(radius: 8, corner: 12)` like a built-in. Show:
 (a) the ViewModifier struct,
 (b) the View extension that makes it ergonomic.
 */

/*:
 TODO: 1) struct RoundedShadowStyle: ViewModifier { ... }
 TODO: 2) extension View { func roundedShadow(...) -> some View { ... } }
 */

/*:
 ## Drill 4 — PreferenceKey — child reports up
 */

/*:
 ### Prompt 4 — from-scratch
 Read the on-screen height of a child view back to the parent so the
 parent can size a sibling to match.

 **Talk-track**: "Environment goes parent→child. PreferenceKey goes
 child→parent. The child writes via `.preference(key:value:)`, the
 ancestor reads via `.onPreferenceChange(...)`."
 */

/*:
 TODO: HeightKey: PreferenceKey with defaultValue 0 and reduce = max
 */

struct ParentView: View {
    @State private var measuredHeight: CGFloat = 0
    var body: some View {
        VStack {
            // TODO: a Text inside a GeometryReader that publishes its height
            // TODO: a Color.red sized to height = measuredHeight
            Text("placeholder")
        }
    }
}

/*:
 ## Drill 5 — Data-driven navigation in MVVM
 */

/*:
 ### Prompt 5 — from-scratch
 The interviewer asks: "In MVVM SwiftUI, where does navigation live?"
 Build a list view + detail view where tapping a row pushes the detail.
 Navigation state should live in the view-model, not in `@State` on the View.
 */

struct Post: Identifiable, Hashable {
    let id = UUID()
    let title: String
}

@Observable
final class FeedVM {
    var posts: [Post] = [.init(title: "Hello"), .init(title: "World")]
    // TODO: navigation state — selected post (or nil) lives here
}

struct FeedView: View {
    @State private var vm = FeedVM()
    var body: some View {
        // TODO: NavigationStack
        // TODO: List driven by vm.posts; tap selects
        // TODO: navigationDestination(item:) bound to vm.selected
        Text("placeholder")
    }
}

/*:
 ## Drill 6 — Custom Layout — wrapping tag cloud
 */

/*:
 ### Prompt 6 — from-scratch
 Build a `TagCloudLayout: Layout` that wraps tags onto multiple rows when
 they don't fit horizontally.

 **Talk-track**: "The Layout protocol gives you sizeThatFits and
 placeSubviews. I receive a proposed size from the parent, walk subviews
 measuring each, advance an x-cursor, wrap to next row when overflowing."
 */

struct TagCloudLayout_Empty: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // TODO
        .zero
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // TODO
    }
}

/*:
 ## Drill 7 — Focus & keyboard with @FocusState
 */

/*:
 ### Prompt 7 — from-scratch
 LoginForm has username + password fields. On appear, focus the username.
 On submit, move focus to password; if password submit, dismiss focus.
 */

struct LoginForm_Empty: View {
    @State private var user = ""
    @State private var pass = ""
    // TODO: enum Field { case user, pass }
    // TODO: @FocusState
    var body: some View {
        Form {
            TextField("User", text: $user)
            SecureField("Pass", text: $pass)
        }
    }
}

/*:
 ## Drill 8 — NavigationStack(path:) — deep link
 */

/*:
 ### Prompt 8 — bug-hunt
 The deep-link below silently does nothing. Why?
 */

enum Route08: Hashable { case detail(Int); case profile(String) }

struct App08: View {
    @State private var path = NavigationPath()
    var body: some View {
        NavigationStack(path: $path) {
            Button("Deep link") {
                path.append(Route08.detail(7))
                path.append(Route08.profile("Ana"))
            }
            // BUG: missing something here.
        }
    }
}

/*:
 TODO: fix App08 so the deep link actually pushes the screens.
 */

/*:
 ## Drill 9 — AnyLayout — adapt HStack/VStack
 */

/*:
 ### Prompt 9 — from-scratch
 Build a screen whose layout is HStack on regular size class and VStack
 on compact, switching dynamically when the size class changes —
 preserving subview identity.
 */

struct AdaptiveScreen_Empty: View {
    @Environment(\.horizontalSizeClass) var hSize
    var body: some View {
        // TODO: AnyLayout switching HStackLayout / VStackLayout
        Text("placeholder")
    }
}

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1 -----
 private struct APIClientKey: EnvironmentKey {
     static let defaultValue: any APIClient = LiveAPI()
 }
 extension EnvironmentValues {
     var api: any APIClient {
         get { self[APIClientKey.self] }
         set { self[APIClientKey.self] = newValue }
     }
 }
 struct DeepFeedView: View {
     @Environment(\.api) private var api
     @State private var items: [String] = []
     var body: some View {
         List(items, id: \.self) { Text($0) }
             .task { items = (try? await api.fetch()) ?? [] }
     }
 }

 // ----- Drill 2 -----
 // The bug depends on how the parent presents ProfileView. Two cases:
 //
 // (a) Parent does ProfileView(userId: userId).id(userId)
 //     → Forces remount on every userId change → @State (scrollPos) RESETS.
 //     Fix if you DON'T want reset: drop the .id(userId).
 //
 // (b) Parent re-renders ProfileView with new userId, no .id, same
 //     position+type → SwiftUI keeps @State, scrollPos PERSISTS (which
 //     might also be wrong — stale position for new user).
 //
 // Rule: .id(value) = "this is a new logical view when value changes".
 // Use only when you WANT to reset state.

 // ----- Drill 3 -----
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

 // ----- Drill 4 -----
 struct HeightKey: PreferenceKey {
     static var defaultValue: CGFloat = 0
     static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
         value = max(value, nextValue())
     }
 }
 struct ParentView: View {
     @State private var measuredHeight: CGFloat = 0
     var body: some View {
         VStack {
             Text("Watched line")
                 .background(GeometryReader { proxy in
                     Color.clear.preference(key: HeightKey.self, value: proxy.size.height)
                 })
             Color.red.frame(height: measuredHeight)
         }
         .onPreferenceChange(HeightKey.self) { measuredHeight = $0 }
     }
 }

 // ----- Drill 5 -----
 @Observable
 final class FeedVM {
     var posts: [Post] = [...]
     var selected: Post?
 }
 struct FeedView: View {
     @State private var vm = FeedVM()
     var body: some View {
         NavigationStack {
             List(vm.posts) { post in
                 Button(post.title) { vm.selected = post }
             }
             .navigationDestination(item: $vm.selected) { post in
                 PostDetail(post: post)
             }
         }
     }
 }

 // ----- Drill 6 -----
 struct TagCloudLayout: Layout {
     var spacing: CGFloat = 6
     func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
         let maxWidth = proposal.width ?? .infinity
         var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
         for sv in subviews {
             let size = sv.sizeThatFits(.unspecified)
             if x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
             x += size.width + spacing
             rowHeight = max(rowHeight, size.height)
         }
         return CGSize(width: maxWidth, height: y + rowHeight)
     }
     func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
         var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
         for sv in subviews {
             let size = sv.sizeThatFits(.unspecified)
             if x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
             sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
             x += size.width + spacing
             rowHeight = max(rowHeight, size.height)
         }
     }
 }

 // ----- Drill 7 -----
 struct LoginForm: View {
     enum Field { case user, pass }
     @State private var user = ""
     @State private var pass = ""
     @FocusState private var focused: Field?
     var body: some View {
         Form {
             TextField("User", text: $user).focused($focused, equals: .user).submitLabel(.next)
             SecureField("Pass", text: $pass).focused($focused, equals: .pass).submitLabel(.go)
         }
         .onAppear { focused = .user }
         .onSubmit { focused = focused == .user ? .pass : nil }
     }
 }

 // ----- Drill 8 -----
 struct App08_Fixed: View {
     @State private var path = NavigationPath()
     var body: some View {
         NavigationStack(path: $path) {
             Button("Deep link") {
                 path.append(Route08.detail(7))
                 path.append(Route08.profile("Ana"))
             }
             .navigationDestination(for: Route08.self) { route in   // ← THE FIX
                 switch route {
                 case .detail(let id): Text("Detail \(id)")
                 case .profile(let name): Text("Profile \(name)")
                 }
             }
         }
     }
 }
 // Without .navigationDestination(for:), NavigationStack silently drops
 // pushes of unregistered types.

 // ----- Drill 9 -----
 struct AdaptiveScreen: View {
     @Environment(\.horizontalSizeClass) var hSize
     var body: some View {
         let layout: AnyLayout = hSize == .regular
             ? AnyLayout(HStackLayout(spacing: 16))
             : AnyLayout(VStackLayout(spacing: 16))
         layout {
             SidebarView()
             DetailView()
         }
     }
 }
 // The closure-call works because Layout is a function-like type.
 // Wrap in withAnimation to get smooth transitions when size class flips.

*/
