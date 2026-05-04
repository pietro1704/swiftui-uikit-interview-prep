/*:
 # 02 — SwiftUI Intermediate

 Once Page 01 is comfortable, these are the second-round drills senior
 interviewers reach for. Topics: environment-based DI, identity tricks,
 view modifiers, preference keys, navigation as data.

 ----
 */
import SwiftUI

// MARK: - Drill 1: Inject a dependency without prop-drilling

/*:
 ### Prompt 1
 You have an `APIClient` protocol used by 5 nested views. The interviewer
 says: "I don't want a singleton, and I don't want to thread the client
 through every initializer. How would you do it in SwiftUI?"

 **Talk-track**:
 > "SwiftUI's Environment is the canonical answer: define an EnvironmentKey
 > with a default, expose a property on EnvironmentValues, inject at the
 > top with .environment(\\.apiClient, ...), read deep with @Environment.
 > Tests/previews override per-call site."

 Fill in the blanks below.
 */

protocol APIClient {
    func fetch() async throws -> [String]
}

struct LiveAPI: APIClient {
    func fetch() async throws -> [String] { ["Apple", "Banana"] }
}

// TODO: 1) define a private EnvironmentKey for APIClient
// TODO: 2) extension EnvironmentValues with `var api: any APIClient`

struct DeepFeedView: View {
    // TODO: read the API client from the environment
    var body: some View {
        // TODO: load on .task and display results
        Text("placeholder")
    }
}

// At the app entry: ContentView().environment(\.api, LiveAPI())

// MARK: - Drill 2: View identity surprise

/*:
 ### Prompt 2
 The detail screen below loses its scroll position whenever the user
 picks a different item from a menu. Why, and what's the one-liner fix?

 **Hint**: identity, identity, identity.
 */

struct ProfileView: View {
    let userId: UUID
    @State private var scrollPos: CGFloat = 0     // resets when?

    var body: some View {
        ScrollView { Text("User: \(userId.uuidString.prefix(8))") }
        // ☝️  No .id() — and the parent passes a fresh ProfileView each
        //     time `userId` changes. Identity stable? Or not?
    }
}

// MARK: - Drill 3: Reusable modifier with parameters

/*:
 ### Prompt 3
 Build a modifier `roundedShadow(radius:corner:)` so any view can call
 `.roundedShadow(radius: 8, corner: 12)` like a built-in. The interviewer
 wants to see (a) the ViewModifier struct, (b) the View extension that
 makes it ergonomic.
 */

// TODO: 1) struct RoundedShadowStyle: ViewModifier { ... }
// TODO: 2) extension View { func roundedShadow(...) -> some View { ... } }

// MARK: - Drill 4: PreferenceKey — child reports up

/*:
 ### Prompt 4
 Read the on-screen height of a child view back to the parent so the
 parent can size a sibling to match.

 **Talk-track**:
 > "Environment goes parent→child. PreferenceKey goes child→parent. The
 > child writes via `.preference(key:value:)`, the ancestor reads via
 > `.onPreferenceChange(...)`. The PreferenceKey type with `defaultValue`
 > and `reduce(_:_:)` defines how multiple children combine."
 */

// TODO: HeightKey: PreferenceKey with defaultValue 0 and reduce = max

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

// MARK: - Drill 5: Data-driven navigation in MVVM

/*:
 ### Prompt 5
 The interviewer asks: "In MVVM SwiftUI, where does navigation live?"
 Build a list view + detail view where tapping a row pushes the detail.
 Navigation state should live in the view-model, not in `@State` on the View.
 */

import Observation

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

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1: Environment DI -----
 private struct APIClientKey: EnvironmentKey {
     static let defaultValue: any APIClient = LiveAPI()
 }
 extension EnvironmentValues {
     var api: any APIClient {
         get { self[APIClientKey.self] }
         set { self[APIClientKey.self] = newValue }
     }
 }
 // iOS 18+: even shorter
 // extension EnvironmentValues { @Entry var api: any APIClient = LiveAPI() }

 struct DeepFeedView: View {
     @Environment(\.api) private var api
     @State private var items: [String] = []
     var body: some View {
         List(items, id: \.self) { Text($0) }
             .task { items = (try? await api.fetch()) ?? [] }
     }
 }
 // ContentView().environment(\.api, MockAPI()) for tests/previews.

 // ----- Drill 2: Identity surprise -----
 // The bug: ProfileView keeps scrollPos as @State, but as `userId` changes,
 // the *position* and *type* of ProfileView are still identical from
 // SwiftUI's POV — so it KEEPS the old @State, including stale scroll
 // position.
 //
 // Wait — that's the OPPOSITE of "loses position." Re-reading the prompt…
 //
 // The actual common bug: parent does
 //   if let userId { ProfileView(userId: userId) } else { EmptyView() }
 // OR uses .id(userId) — that forces remount, RESETTING @State. The user
 // wants the position preserved across the same view instance.
 //
 // Fix when you DO want a fresh state per user:
 //   ProfileView(userId: userId).id(userId)
 // Fix when you DON'T:
 //   Don't add .id(); don't switch parent type; lift scrollPos into a
 //   parent-owned dictionary keyed by userId so it survives rebuilds.

 // ----- Drill 3: Modifier -----
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

 // ----- Drill 4: PreferenceKey -----
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
                 .background(
                     GeometryReader { proxy in
                         Color.clear.preference(key: HeightKey.self, value: proxy.size.height)
                     }
                 )
             Color.red.frame(height: measuredHeight)
         }
         .onPreferenceChange(HeightKey.self) { measuredHeight = $0 }
     }
 }

 // ----- Drill 5: Data-driven navigation -----
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
 // Senior framing: "Navigation INTENT lives in VM as state. The View
 //  binds that state to NavigationStack/sheet/fullScreenCover. For
 //  multi-step flows, hoist the whole NavigationPath into a Router
 //  @Observable shared via Environment."

*/
