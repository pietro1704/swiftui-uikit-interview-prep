import Foundation

// 15 advanced SwiftUI questions covering: Observation, view identity,
// custom modifiers, geometry, focus, navigation, layout, environment.

extension QuestionBank {
    static let swiftUI: [Question] = [
        Question(
            id: 6,
            topic: .swiftUI,
            prompt: """
            What is the *practical* difference between `ObservableObject` + \
            `@Published` and the new `@Observable` macro for a view-model?
            """,
            options: [
                "`@Observable` is just renamed — same Combine plumbing under the hood.",
                "`@Observable` tracks property reads at view-body level, so views only re-render when properties they actually read change; ObservableObject re-renders any subscriber on any @Published change.",
                "`@Observable` requires iOS 18; ObservableObject works back to 13 and is otherwise identical.",
                "`@Observable` removes the need for `@State` in views."
            ],
            correctIndex: 1,
            explanation: """
            The Observation framework instruments property access *inside* a \
            view's body. SwiftUI registers fine-grained dependencies and \
            invalidates only the views that read changed keypaths. \
            ObservableObject coarsely re-renders every subscriber whenever any \
            @Published fires. Real perf wins on big screens. Note: you do still \
            want @State to OWN an @Observable VM in a view.
            """,
            starterCode: """
            class OldVM: ObservableObject {
                @Published var query = ""
                @Published var results: [String] = []
            }

            // Migrate to the @Observable macro.
            """,
            referenceSolution: """
            import Observation
            @Observable
            final class NewVM {
                var query = ""
                var results: [String] = []
            }
            struct Search: View {
                @State private var vm = NewVM()
                var body: some View {
                    TextField("Query", text: $vm.query)
                    List(vm.results, id: \\.self) { Text($0) }
                }
            }
            """
        ),
        Question(
            id: 7,
            topic: .swiftUI,
            prompt: """
            Why is wrapping a whole screen in a `GeometryReader` to "get the \
            width" usually a bad idea, and what's the modern alternative?
            """,
            options: [
                "It's fine — GeometryReader is the official way to read size.",
                "GeometryReader fills its parent and reports its own (proposed) size, breaking layout for siblings; use `onGeometryChange` (iOS 18+) or a `PreferenceKey` reading a fixed-size child.",
                "GeometryReader is deprecated in iOS 17.",
                "It only fails inside `LazyVStack`."
            ],
            correctIndex: 1,
            explanation: """
            GeometryReader proposes its parent's size to its child *and* takes \
            up all available space — turning otherwise-flexible layouts into \
            "fill the screen". Modern fix: `onGeometryChange(for:of:action:)` \
            (iOS 18) on the specific view, or a PreferenceKey on a Color.clear \
            background scoped to JUST the child you want to measure.
            """,
            starterCode: """
            struct Card: View {
                var body: some View {
                    GeometryReader { proxy in
                        Text("Width: \\(proxy.size.width)")
                    }
                }
            }
            """,
            referenceSolution: """
            // iOS 17 — PreferenceKey
            struct WidthKey: PreferenceKey {
                static var defaultValue: CGFloat = 0
                static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
                    value = max(value, nextValue())
                }
            }
            struct Card: View {
                @State private var width: CGFloat = 0
                var body: some View {
                    Text("Width: \\(width)")
                        .background(GeometryReader { p in
                            Color.clear.preference(key: WidthKey.self, value: p.size.width)
                        })
                        .onPreferenceChange(WidthKey.self) { width = $0 }
                }
            }
            // iOS 18: .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            """
        ),
        Question(
            id: 8,
            topic: .swiftUI,
            prompt: """
            When does SwiftUI tear down and rebuild a view's state (lose `@State`), \
            and how do you preserve identity across data changes in a list?
            """,
            options: [
                "State persists as long as the view's *type* matches; force a rebuild via `.id(...)`. Stable identity in lists comes from `ForEach(_, id:)` keyed on a true unique id.",
                "State always persists once allocated.",
                "Identity in `ForEach` doesn't matter; SwiftUI diffs by type.",
                "`.id()` is purely for testing — it doesn't affect view lifetime."
            ],
            correctIndex: 0,
            explanation: """
            Identity = type + structural position + explicit `.id()`. Change \
            any of those and SwiftUI considers it a *new* view, allocating new \
            @State. Classic bug: `ForEach(items, id: \\.self)` on a value type \
            that mutates — identity churns and animations break. Use a stable \
            unique id (UUID, primary key); reach for `.id()` only when you \
            *want* a remount (e.g., reset a form on user switch).
            """,
            starterCode: """
            ForEach(items, id: \\.self) { item in
                EditableRow(item: item)
            }
            """,
            referenceSolution: """
            struct Item: Identifiable, Hashable {
                let id: UUID
                var title: String
            }
            ForEach(items) { item in
                EditableRow(item: item)
            }
            // Intentional remount on user switch:
            ProfileView(user: currentUser).id(currentUser.id)
            """
        ),
        Question(
            id: 9,
            topic: .swiftUI,
            prompt: """
            You build a custom `RoundedShadowStyle` modifier you'll reuse \
            across many views. What's the right way to package it?
            """,
            options: [
                "Subclass `View` and override `body`.",
                "Define `struct RoundedShadowStyle: ViewModifier`, plus an `extension View` helper that returns `.modifier(RoundedShadowStyle(...))`.",
                "Stuff it into a global `@ViewBuilder` function with `AnyView`.",
                "Use `PreferenceKey` to broadcast styling values upward."
            ],
            correctIndex: 1,
            explanation: """
            ViewModifier + a `View` extension is the canonical recipe: \
            composable, the call-site reads `.roundedShadow(radius: 8)` like a \
            built-in, and SwiftUI keeps efficient diffing. Avoid AnyView (kills \
            type info); PreferenceKey is for parent-bound communication, not \
            styling.
            """,
            starterCode: """
            // Goal: usage site reads `.roundedShadow(radius: 8, corner: 12)`
            struct RoundedShadowStyle {
                // TODO
            }
            """,
            referenceSolution: """
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
            """
        ),
        Question(
            id: 10,
            topic: .swiftUI,
            prompt: """
            Inside a SwiftUI `List`, `.matchedGeometryEffect` glitches when \
            animating a row into a detail. Most common root cause?
            """,
            options: [
                "List doesn't support matchedGeometryEffect at all.",
                "Both views must share the same Namespace AND must be onscreen *simultaneously* during the transition — which List's recycling defeats unless you orchestrate visibility (e.g., overlaying the detail in a ZStack).",
                "matchedGeometryEffect requires a `NavigationStack` to drive the transition.",
                "You forgot `.transition(.scale)` — that's all."
            ],
            correctIndex: 1,
            explanation: """
            `matchedGeometryEffect` interpolates between two CONCURRENTLY \
            mounted views sharing the same `id` in the same `Namespace`. \
            Lists virtualize rows, so the source disappears the moment you \
            push to detail. Recipe: keep the source visible (overlay the \
            detail above the list with a ZStack + custom transition), or use \
            the iOS 18 zoom transition API.
            """,
            starterCode: """
            @Namespace private var ns
            // List row .matchedGeometryEffect(id: item.id, in: ns)
            // Pushed Detail uses same id+ns — animation glitches.
            """,
            referenceSolution: """
            struct Gallery: View {
                @Namespace private var ns
                @State private var selected: Item?
                let items: [Item] = []
                var body: some View {
                    ZStack {
                        List(items) { item in
                            Thumbnail(item: item)
                                .matchedGeometryEffect(id: item.id, in: ns, isSource: selected == nil)
                                .onTapGesture { withAnimation(.spring) { selected = item } }
                        }
                        if let item = selected {
                            Detail(item: item)
                                .matchedGeometryEffect(id: item.id, in: ns, isSource: false)
                                .onTapGesture { withAnimation(.spring) { selected = nil } }
                        }
                    }
                }
            }
            """
        ),

        // ==============================================================
        // NEW QUESTIONS — Q31–40
        // ==============================================================

        Question(
            id: 31,
            topic: .swiftUI,
            prompt: """
            You need a horizontal layout that wraps to the next row when items \
            don't fit (a "tag cloud"). The interviewer asks: do you reach for \
            HStack? LazyVGrid? Custom Layout?
            """,
            options: [
                "HStack — it auto-wraps when overflow.",
                "LazyVGrid — that's exactly what it does.",
                "Custom `Layout` (iOS 16+) — neither HStack nor LazyVGrid wrap. The Layout protocol gives you `sizeThatFits` and `placeSubviews` to compute wrapping yourself.",
                "It's impossible without UIKit."
            ],
            correctIndex: 2,
            explanation: """
            HStack is single-row, no wrapping. LazyVGrid uses *fixed* columns \
            — items don't size themselves to content. The Layout protocol is \
            purpose-built for this: receive proposed size, lay out children \
            row-by-row, return the total size used.
            """,
            starterCode: """
            // Goal: a TagCloudLayout that wraps tags onto multiple rows.
            struct TagCloudLayout: Layout {
                func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
                    // TODO
                    .zero
                }
                func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
                    // TODO
                }
            }
            """,
            referenceSolution: """
            struct TagCloudLayout: Layout {
                var spacing: CGFloat = 6
                func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
                    let maxWidth = proposal.width ?? .infinity
                    var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
                    for sv in subviews {
                        let size = sv.sizeThatFits(.unspecified)
                        if x + size.width > maxWidth {
                            x = 0; y += rowHeight + spacing; rowHeight = 0
                        }
                        x += size.width + spacing
                        rowHeight = max(rowHeight, size.height)
                    }
                    return CGSize(width: maxWidth, height: y + rowHeight)
                }
                func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
                    var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
                    for sv in subviews {
                        let size = sv.sizeThatFits(.unspecified)
                        if x + size.width > bounds.maxX {
                            x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
                        }
                        sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                        x += size.width + spacing
                        rowHeight = max(rowHeight, size.height)
                    }
                }
            }
            """
        ),
        Question(
            id: 32,
            topic: .swiftUI,
            prompt: """
            `.task { await load() }` vs `.onAppear { Task { await load() } }`. \
            Why prefer `.task`?
            """,
            options: [
                "They're equivalent.",
                "`.task` is tied to view lifetime: when the view disappears, the task is automatically CANCELLED. `.onAppear { Task { } }` creates an unstructured task that keeps running after dismissal — often causing late state mutations or wasted network.",
                "`.onAppear` doesn't support async — it's deprecated.",
                "`.task` runs on a background thread; `onAppear` runs on main."
            ],
            correctIndex: 1,
            explanation: """
            `.task` ties the Task lifecycle to the View's onAppear/onDisappear, \
            cancelling on disappear. The unstructured `Task { }` from inside \
            `onAppear` has no such tie — it'll keep running. This is the \
            #1 source of "view dismissed but I still got a result back" bugs.
            """,
            starterCode: """
            // BUG: this view leaks the load() task if dismissed mid-flight.
            struct FeedView: View {
                @State private var posts: [Post] = []
                var body: some View {
                    List(posts) { Text($0.title) }
                        .onAppear {
                            Task {
                                posts = (try? await loadPosts()) ?? []
                            }
                        }
                }
            }
            """,
            referenceSolution: """
            struct FeedView: View {
                @State private var posts: [Post] = []
                var body: some View {
                    List(posts) { Text($0.title) }
                        .task {
                            posts = (try? await loadPosts()) ?? []
                        }
                }
            }
            // .task(id: someValue) { } also re-runs when `id` changes —
            // perfect for "reload when the user changes the filter".
            """
        ),
        Question(
            id: 33,
            topic: .swiftUI,
            prompt: """
            How do you programmatically focus a TextField, and what's the \
            common mistake when wiring `@FocusState`?
            """,
            options: [
                "There's no programmatic focus in SwiftUI.",
                "Declare `@FocusState private var focused: Field?` (or Bool) on the parent, attach `.focused($focused, equals: .username)` to each field, then assign `focused = .username` to focus. Common bug: declaring `@FocusState` on the SAME view that contains the field — works, but if you put it on a subview while the field is on the parent, focus binding breaks.",
                "Wrap UIKit's UITextField via UIViewRepresentable — SwiftUI doesn't support it natively.",
                "Use `.onAppear { UIResponder.becomeFirstResponder() }` directly."
            ],
            correctIndex: 1,
            explanation: """
            FocusState is a SwiftUI property wrapper for tracking and \
            controlling focus. Pattern: enum of fields, `@FocusState var \
            focused: Field?`, `.focused($focused, equals: .username)` per \
            field. Trap: FocusState ownership matters — declare it on the \
            view that wraps the fields; binding across boundaries needs care.
            """,
            starterCode: """
            struct LoginForm: View {
                @State private var user = ""
                @State private var pass = ""
                // TODO: add @FocusState; auto-focus username on appear.
                var body: some View {
                    Form {
                        TextField("User", text: $user)
                        SecureField("Pass", text: $pass)
                    }
                }
            }
            """,
            referenceSolution: """
            struct LoginForm: View {
                enum Field { case user, pass }
                @State private var user = ""
                @State private var pass = ""
                @FocusState private var focused: Field?
                var body: some View {
                    Form {
                        TextField("User", text: $user).focused($focused, equals: .user)
                        SecureField("Pass", text: $pass).focused($focused, equals: .pass)
                    }
                    .onAppear { focused = .user }
                    .onSubmit { focused = focused == .user ? .pass : nil }
                }
            }
            """
        ),
        Question(
            id: 34,
            topic: .swiftUI,
            prompt: """
            What's `@Bindable` for, and how is it different from `@Binding`?
            """,
            options: [
                "Same thing, renamed in iOS 18.",
                "`@Bindable` is used INSIDE a view to take an `@Observable` object passed as a regular parameter and produce bindings to its properties (e.g., `$user.name`). `@Binding` is the existing wrapper for receiving a single binding from a parent — it doesn't create bindings to multiple properties.",
                "`@Bindable` is for SwiftData models only.",
                "`@Bindable` makes a view's body re-run on every state change — opposite of @Observable."
            ],
            correctIndex: 1,
            explanation: """
            `@Bindable` (iOS 17+) bridges plain `@Observable` parameters into \
            bindings within a child view. Without it, `$user.name` doesn't \
            compile when `user` came in as a regular `let` parameter. With \
            `@Bindable var user: User`, you get `$user.name`, `$user.email` \
            etc. Use case: child view that edits multiple properties of an \
            object owned by the parent.
            """,
            starterCode: """
            @Observable final class User { var name = ""; var email = "" }

            // BUG: this child view can't bind via $user.name
            struct EditUserView: View {
                let user: User
                var body: some View {
                    Form {
                        TextField("Name", text: $user.name)   // ❌ won't compile
                    }
                }
            }
            """,
            referenceSolution: """
            struct EditUserView: View {
                @Bindable var user: User           // <- the fix
                var body: some View {
                    Form {
                        TextField("Name", text: $user.name)
                        TextField("Email", text: $user.email)
                    }
                }
            }
            // Parent passes by value:
            //   EditUserView(user: parentVM.currentUser)
            """
        ),
        Question(
            id: 35,
            topic: .swiftUI,
            prompt: """
            You bind `NavigationStack(path: $path)` to `@State var path = NavigationPath()`. \
            On a deep-link to detail(7) → profile("Ana"), the back-stack appears empty. Why?
            """,
            options: [
                "NavigationPath is broken in iOS 17.",
                "You probably appended values whose types AREN'T registered via `.navigationDestination(for:)`. Each value type pushed onto NavigationPath needs a matching `.navigationDestination(for: T.self) { ... }`. If type T isn't registered, the stack silently drops the push.",
                "Deep links require `NavigationLink(value:)`, not path append.",
                "NavigationPath persists across launches by default — you saw a stale path."
            ],
            correctIndex: 1,
            explanation: """
            NavigationStack is type-driven: each value pushed is matched against \
            registered destinations. Missing the `.navigationDestination(for:)` \
            for a type means the stack ignores those pushes — silently. Also \
            mind: `.navigationDestination` should be attached *inside* the \
            NavigationStack's content, not on the stack itself.
            """,
            starterCode: """
            enum Route: Hashable { case detail(Int); case profile(String) }
            struct App: View {
                @State private var path = NavigationPath()
                var body: some View {
                    NavigationStack(path: $path) {
                        Button("Deep link") {
                            path.append(Route.detail(7))
                            path.append(Route.profile("Ana"))
                        }
                        // BUG: no .navigationDestination(for: Route.self)
                    }
                }
            }
            """,
            referenceSolution: """
            struct App: View {
                @State private var path = NavigationPath()
                var body: some View {
                    NavigationStack(path: $path) {
                        Button("Deep link") {
                            path.append(Route.detail(7))
                            path.append(Route.profile("Ana"))
                        }
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .detail(let id): DetailView(id: id)
                            case .profile(let name): ProfileView(name: name)
                            }
                        }
                    }
                }
            }
            """
        ),
        Question(
            id: 36,
            topic: .swiftUI,
            prompt: """
            `LazyVStack` inside `ScrollView` vs plain `VStack`: when does the \
            "lazy" actually pay off, and when can it actively hurt you?
            """,
            options: [
                "Lazy is always better — no downside.",
                "Lazy pays off when you have many off-screen children — they aren't created until needed (memory + body work). It HURTS when the children compute expensive layouts at appear time, or rely on `@State` that resets each time they re-enter the lazy stack's window.",
                "Lazy is faster on iPhone but slower on iPad.",
                "Lazy disables animations."
            ],
            correctIndex: 1,
            explanation: """
            LazyVStack defers child creation until they enter the visible \
            window — huge win for long lists. Trap 1: each appear/disappear \
            tears down state on lazily-created children. Trap 2: heavy `.task` \
            or `body` work runs on every appear, not once. For 10-20 small \
            children, plain VStack is often simpler AND fine.
            """,
            starterCode: """
            // No code — verbal answer.
            // Discuss: when LazyVStack is wrong choice.
            """,
            referenceSolution: """
            // RIGHT for: long feeds, paginated lists, anything > ~50 children.
            // WRONG for: small fixed sets where you want @State to persist;
            //  expensive eager work in body that should run once.
            //
            // Subtlety: LazyVStack creates children IN ITS OWN identity scope.
            // If the lazy stack is inside a List (which is itself lazy),
            // you're double-virtualizing — usually a bug.
            """
        ),
        Question(
            id: 37,
            topic: .swiftUI,
            prompt: """
            Render a list with sections (title + items per section). Pick the \
            idiomatic structure.
            """,
            options: [
                "Nested ForEach with manual headers.",
                "List with `Section { } header: { }` for each section, plus a single ForEach over the section data.",
                "UICollectionView via UIViewRepresentable.",
                "Any of the above; SwiftUI doesn't have section primitives."
            ],
            correctIndex: 1,
            explanation: """
            `Section` is a first-class SwiftUI primitive. Use it inside `List` \
            (and `Form`) for grouped content with headers/footers. The data \
            shape is usually `[Section]` where each Section has a title + \
            items, and you ForEach over that.
            """,
            starterCode: """
            struct Group { let title: String; let items: [String] }
            let groups: [Group] = [
                .init(title: "Fruits", items: ["Apple", "Mango"]),
                .init(title: "Veggies", items: ["Kale", "Carrot"]),
            ]
            // TODO: render as List with sections.
            """,
            referenceSolution: """
            List {
                ForEach(groups, id: \\.title) { group in
                    Section(group.title) {
                        ForEach(group.items, id: \\.self) { Text($0) }
                    }
                }
            }
            // For collapsible sections: use DisclosureGroup inside the row instead.
            """
        ),
        Question(
            id: 38,
            topic: .swiftUI,
            prompt: """
            What does `@ViewBuilder` actually do when the compiler sees:
            ```
            @ViewBuilder var body: some View {
                if cond { Text("a") } else { Image(systemName: "x") }
            }
            ```
            """,
            options: [
                "It magically erases the type to AnyView.",
                "It's a Result Builder. The if/else expands to `_ConditionalContent<Text, Image>`, a TupleView wraps multiple statements, etc. The compiler builds a deterministic tree of TupleView/ConditionalContent — still a single concrete type known at compile time. Hence the `some View` opaque return works without AnyView.",
                "It runs the closure twice and picks the result.",
                "It's a runtime feature that requires Objective-C."
            ],
            correctIndex: 1,
            explanation: """
            ViewBuilder is `@resultBuilder` ViewBuilder under the hood. It has \
            `buildBlock`, `buildEither(first:)`, `buildEither(second:)`, \
            `buildOptional`, `buildArray` etc. The compiler rewrites your view \
            DSL into nested type expressions — the result type is concrete \
            (e.g., `_ConditionalContent<TupleView<...>, Text>`), so SwiftUI \
            can diff it efficiently. AnyView only enters when YOU type-erase \
            manually, which usually you shouldn't.
            """,
            starterCode: """
            // No code — verbal answer.
            // Talk-track: result builders, _ConditionalContent, TupleView,
            // why AnyView is rare.
            """,
            referenceSolution: """
            // What the compiler turns this into (mental model):
            //   if cond {
            //     ViewBuilder.buildEither(first: Text("a"))
            //   } else {
            //     ViewBuilder.buildEither(second: Image(systemName: "x"))
            //   }
            //   // returns _ConditionalContent<Text, Image>
            //
            // For three statements:
            //   ViewBuilder.buildBlock(a, b, c)
            //   // returns TupleView<(A, B, C)>
            //
            // Why this matters in interviews: you can hand-implement a tiny
            // result builder (see Lesson 17 / livecoding page 04) and explain
            // how SwiftUI's DSL has zero runtime overhead.
            """
        ),
        Question(
            id: 39,
            topic: .swiftUI,
            prompt: """
            You want a screen whose layout is HStack on iPad and VStack on \
            iPhone, with a single source of truth. What's the modern SwiftUI \
            answer (iOS 16+)?
            """,
            options: [
                "Two separate views, picked via `if UIDevice.current.userInterfaceIdiom == .pad`.",
                "`AnyLayout(condition ? HStackLayout() : VStackLayout())` wrapping the same content. The Layout protocol exposes value-type layouts that you can swap dynamically while keeping animation continuity.",
                "Use Mac Catalyst conditional compilation.",
                "GeometryReader + manual frame math."
            ],
            correctIndex: 1,
            explanation: """
            iOS 16's Layout protocol gives you `HStackLayout`/`VStackLayout` \
            as value types you can wrap with `AnyLayout` and swap on a flag. \
            Crucially, identity is preserved across the swap — so SwiftUI \
            animates layout changes smoothly when you switch container types.
            """,
            starterCode: """
            struct AdaptiveScreen: View {
                @Environment(\\.horizontalSizeClass) var hSize
                var body: some View {
                    // TODO: use AnyLayout to switch HStack/VStack
                    Text("placeholder")
                }
            }
            """,
            referenceSolution: """
            struct AdaptiveScreen: View {
                @Environment(\\.horizontalSizeClass) var hSize
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
            // The closure-style call works because Layout is a function-like type.
            // Switching the layout animates if wrapped in withAnimation.
            """
        ),
        Question(
            id: 40,
            topic: .swiftUI,
            prompt: """
            `@Environment(\\.dismiss)` vs `@EnvironmentObject` vs `@Environment(MyType.self)` \
            — explain the three and when each is right.
            """,
            options: [
                "They're equivalent.",
                "`@Environment(\\.dismiss)` reads a *value* keyed by EnvironmentKey (here, the dismiss action). `@EnvironmentObject` (legacy, requires ObservableObject + .environmentObject) injects a reference type. `@Environment(MyType.self)` is the iOS 17+ way for `@Observable` types — replaces EnvironmentObject and uses .environment(value).",
                "@EnvironmentObject is for primitives, @Environment is for classes.",
                "@Environment is read-only; the others are read-write."
            ],
            correctIndex: 1,
            explanation: """
            Three flavors: \
            (a) `@Environment(\\.dismiss)` etc. — small, predefined values; \
            (b) `@EnvironmentObject MyVM` — pre-iOS 17, ObservableObject-only; \
            (c) `@Environment(MyVM.self)` — iOS 17+ Observation way for \
            @Observable. For new code on iOS 17+, prefer (c). EnvironmentObject \
            still works but has worse re-render behavior.
            """,
            starterCode: """
            // No code — verbal answer + small migration sketch.
            """,
            referenceSolution: """
            // OLD (pre-iOS 17):
            class Theme: ObservableObject { @Published var color: Color = .blue }
            struct App: App {
                @StateObject private var theme = Theme()
                var body: some Scene {
                    WindowGroup { ContentView().environmentObject(theme) }
                }
            }
            struct DeepView: View {
                @EnvironmentObject var theme: Theme
                var body: some View { Color(theme.color) }
            }

            // NEW (iOS 17+):
            @Observable final class Theme { var color: Color = .blue }
            @main struct App: App {
                @State private var theme = Theme()
                var body: some Scene {
                    WindowGroup { ContentView().environment(theme) }
                }
            }
            struct DeepView: View {
                @Environment(Theme.self) private var theme
                var body: some View { Color(theme.color) }
            }
            """
        )
    ]
}
