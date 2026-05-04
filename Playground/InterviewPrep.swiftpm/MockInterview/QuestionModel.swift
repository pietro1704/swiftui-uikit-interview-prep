import Foundation

// MARK: - Question model
//
// Models a single technical interview question for the senior mock interview.
// Mirrors the format senior-LATAM tech leads use: theory + scenario + livecoding
// tweak, rather than algorithmic puzzle. Each question has a single correct
// option, an explanation, an optional starter snippet for the livecoding pane,
// and a reference solution to compare against the candidate's answer.

enum QuestionTopic: String, CaseIterable, Identifiable, Hashable {
    case concurrency = "Concurrency"
    case swiftUI     = "Advanced SwiftUI"
    case architecture = "Architecture"
    case swiftCore    = "Swift deep dive"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .concurrency:  "cpu"
        case .swiftUI:      "rectangle.stack.badge.plus"
        case .architecture: "square.3.layers.3d"
        case .swiftCore:    "swift"
        }
    }
}

struct Question: Identifiable, Hashable {
    let id: Int
    let topic: QuestionTopic
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let starterCode: String
    let referenceSolution: String
}

// MARK: - Question bank
//
// 20 senior-flavored questions, 5 per topic. Phrasing mirrors the kind of
// "talk me through this" + "now tweak the snippet" format senior tech leads
// use in a 1h assessment.

enum QuestionBank {
    static let all: [Question] = concurrency + swiftUI + architecture + swiftCore

    // ===================================================================
    // MARK: Concurrency
    // ===================================================================
    static let concurrency: [Question] = [
        Question(
            id: 1,
            topic: .concurrency,
            prompt: """
            You spawn `Task { await load() }` from a `@MainActor` view. \
            What is the actor isolation of the closure body, and where will \
            `load()` actually run?
            """,
            options: [
                "Always on a background thread, regardless of caller isolation.",
                "Inherits MainActor from the calling context — the closure body runs on the main actor unless explicitly hopped.",
                "Runs on a cooperative-pool thread; only UI updates need `await MainActor.run`.",
                "Behaves like `Task.detached` — fully unstructured and unisolated."
            ],
            correctIndex: 1,
            explanation: """
            Unstructured `Task { }` inherits actor isolation from its enclosing \
            context (priority and task-local values too). Spawned from a \
            @MainActor scope, the body is implicitly @MainActor. Only \
            `Task.detached { }` opts out of inheritance. Knowing this prevents \
            "why is my UI freezing inside Task { }" surprises.
            """,
            starterCode: """
            @MainActor
            final class FeedVM {
                func reload() {
                    Task {
                        // TODO: download JSON off-main, decode,
                        // then publish results back to the UI.
                    }
                }
            }
            """,
            referenceSolution: """
            @MainActor
            final class FeedVM {
                func reload() {
                    Task {
                        // Hop off main for the network/decoding work.
                        let posts = try await Task.detached(priority: .userInitiated) {
                            let (data, _) = try await URLSession.shared.data(from: Self.url)
                            return try JSONDecoder().decode([Post].self, from: data)
                        }.value
                        // Back on MainActor here (inherited isolation).
                        self.posts = posts
                    }
                }
                static let url = URL(string: "https://api.example.com/feed")!
                var posts: [Post] = []
            }
            """
        ),
        Question(
            id: 2,
            topic: .concurrency,
            prompt: """
            An `actor BankAccount { var balance: Int; func deposit(_ n: Int) async { ... } }` \
            calls `await audit.log(balance)` mid-method. After the await resumes, \
            `balance` may differ from what you observed before the await. Why?
            """,
            options: [
                "Actors do not serialize calls; multiple deposits run in parallel.",
                "Actor reentrancy: while suspended on `await`, another reentrant call can mutate state before resumption.",
                "Swift always copies actor state on suspend, so the post-await value is stale.",
                "It can't differ — actors guarantee strict atomicity across await boundaries."
            ],
            correctIndex: 1,
            explanation: """
            Actors serialize *single steps* but are reentrant: an `await` inside \
            an actor method is a suspension point during which other queued \
            messages may execute. Don't assume invariants across awaits — \
            re-read state after resumption, or capture immutable snapshots before \
            suspending. This is the #1 actor pitfall in senior interviews.
            """,
            starterCode: """
            actor BankAccount {
                var balance: Int = 0
                func deposit(_ amount: Int, audit: Auditor) async {
                    balance += amount
                    await audit.log(balance) // suspension point
                    // BUG: any assumption about `balance` here is unsafe.
                    print("New balance is", balance)
                }
            }
            """,
            referenceSolution: """
            actor BankAccount {
                var balance: Int = 0
                func deposit(_ amount: Int, audit: Auditor) async {
                    balance += amount
                    let snapshot = balance        // capture BEFORE await
                    await audit.log(snapshot)
                    print("Logged balance was", snapshot)
                }
            }
            """
        ),
        Question(
            id: 3,
            topic: .concurrency,
            prompt: """
            You have 50 image URLs and want to download them concurrently with a \
            cap of 5 in flight. Which structured-concurrency primitive is \
            idiomatic, and why not the alternatives?
            """,
            options: [
                "`async let` × 50 — the runtime auto-throttles to CPU cores.",
                "`DispatchQueue.concurrentPerform` — Swift Concurrency can't bound parallelism.",
                "`withTaskGroup` adding 5 tasks initially, then `for await` to drain & enqueue the next as each finishes.",
                "Wrap each in `Task.detached` and let cooperative scheduling sort it out."
            ],
            correctIndex: 2,
            explanation: """
            `withTaskGroup` is the canonical bounded-parallelism pattern. \
            `async let` requires a static count and gives no throttling. Pure \
            `Task { }` spawns are unstructured (no cancellation propagation). \
            The bounded TaskGroup pattern — start N, then start one more for \
            each one that finishes — is exactly what senior interviewers ask \
            you to whiteboard.
            """,
            starterCode: """
            func downloadAll(_ urls: [URL]) async throws -> [Data] {
                // TODO: bounded parallelism, max 5 concurrent.
                fatalError("implement me")
            }
            """,
            referenceSolution: """
            func downloadAll(_ urls: [URL], maxConcurrent: Int = 5) async throws -> [Data] {
                try await withThrowingTaskGroup(of: (Int, Data).self) { group in
                    var results = Array<Data?>(repeating: nil, count: urls.count)
                    var next = 0

                    for _ in 0..<min(maxConcurrent, urls.count) {
                        let i = next; next += 1
                        group.addTask {
                            let (d, _) = try await URLSession.shared.data(from: urls[i])
                            return (i, d)
                        }
                    }
                    while let (i, data) = try await group.next() {
                        results[i] = data
                        if next < urls.count {
                            let j = next; next += 1
                            group.addTask {
                                let (d, _) = try await URLSession.shared.data(from: urls[j])
                                return (j, d)
                            }
                        }
                    }
                    return results.compactMap { $0 }
                }
            }
            """
        ),
        Question(
            id: 4,
            topic: .concurrency,
            prompt: """
            Under Swift 6 strict concurrency, which type *cannot* safely cross \
            an actor boundary without an explicit `@unchecked Sendable` or \
            redesign?
            """,
            options: [
                "`struct User { let id: UUID; let name: String }`",
                "`final class Snapshot { let id: UUID; let frozen: [String: Int] }` (all `let`, deep-immutable)",
                "`final class Cache { var entries: [URL: Data] = [:] }` — mutable class without synchronization.",
                "An `enum Status { case idle, loaded(Int) }` with no associated reference types."
            ],
            correctIndex: 2,
            explanation: """
            Sendable is automatic for value types whose stored properties are \
            Sendable, and for `final` classes whose properties are all `let` \
            (and Sendable themselves). A mutable reference-type cache has no \
            synchronization the compiler can prove safe — wrap it in an actor, \
            make it deep-immutable, or annotate `@unchecked Sendable` only \
            after adding your own locking. The compiler will reject it under \
            strict concurrency otherwise.
            """,
            starterCode: """
            final class Cache {
                var entries: [URL: Data] = [:]
            }

            // Goal: make Cache safe to share across tasks
            // without resorting to @unchecked Sendable.
            """,
            referenceSolution: """
            // Idiomatic: convert to an actor.
            actor Cache {
                private var entries: [URL: Data] = [:]
                func get(_ url: URL) -> Data? { entries[url] }
                func set(_ data: Data, for url: URL) { entries[url] = data }
            }

            // Or if you must keep a class, use NSLock + @unchecked.
            final class LockedCache: @unchecked Sendable {
                private var entries: [URL: Data] = [:]
                private let lock = NSLock()
                func get(_ url: URL) -> Data? { lock.lock(); defer { lock.unlock() }; return entries[url] }
                func set(_ data: Data, for url: URL) { lock.lock(); defer { lock.unlock() }; entries[url] = data }
            }
            """
        ),
        Question(
            id: 5,
            topic: .concurrency,
            prompt: """
            A consumer wraps a delegate-callback API as `AsyncStream`. The \
            screen disappears mid-stream. What's the minimum required to avoid \
            a leak and silent zombie producer?
            """,
            options: [
                "Nothing — `AsyncStream` self-terminates when no consumer awaits it.",
                "Hold the producing `Task` and call `.cancel()` in `onDisappear`; the stream's `onTermination` should release the delegate.",
                "Switch to `AsyncThrowingStream` — only that variant can be cancelled.",
                "Use `[weak self]` in the consumer; the framework cancels orphan streams automatically."
            ],
            correctIndex: 1,
            explanation: """
            `AsyncStream` does NOT auto-terminate just because nobody awaits it \
            — its continuation will keep the producer alive until you finish() \
            or cancel the consuming task. The pattern: store the consumer \
            `Task` handle, cancel it in `onDisappear`, and use \
            `continuation.onTermination` inside the stream to detach the \
            delegate. Forgetting either side leaks the producer.
            """,
            starterCode: """
            final class LocationFeed {
                func stream() -> AsyncStream<CLLocation> {
                    AsyncStream { continuation in
                        let manager = CLLocationManager()
                        // TODO: forward delegate updates to continuation
                        // TODO: detach delegate when consumer is gone
                    }
                }
            }
            """,
            referenceSolution: """
            final class LocationFeed: NSObject, CLLocationManagerDelegate {
                private var continuation: AsyncStream<CLLocation>.Continuation?
                private let manager = CLLocationManager()

                func stream() -> AsyncStream<CLLocation> {
                    AsyncStream { continuation in
                        self.continuation = continuation
                        self.manager.delegate = self
                        self.manager.startUpdatingLocation()
                        continuation.onTermination = { [weak self] _ in
                            self?.manager.stopUpdatingLocation()
                            self?.manager.delegate = nil
                        }
                    }
                }
                func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
                    locs.forEach { continuation?.yield($0) }
                }
            }
            // Consumer side:
            // .task { for await loc in feed.stream() { ... } } // task-cancel kills it
            """
        )
    ]

    // ===================================================================
    // MARK: Advanced SwiftUI
    // ===================================================================
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
            @Published fires. Real perf wins on big screens. ✱ minor: you do \
            still want @State to OWN an @Observable VM in a view.
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
                @State private var vm = NewVM()      // @State owns the instance
                var body: some View {
                    TextField("Query", text: $vm.query)   // bindable via $
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
            "fill the screen." Senior interviewers love this gotcha. Modern \
            answer: `onGeometryChange(for:of:action:)` on the specific view \
            you want to measure (iOS 18), or attach a PreferenceKey to a \
            background `Color.clear` reading proxy.size in a GeometryReader \
            scoped to JUST that child.
            """,
            starterCode: """
            struct Card: View {
                var body: some View {
                    GeometryReader { proxy in   // pulls full available size
                        Text("Width: \\(proxy.size.width)")
                    }
                }
            }
            """,
            referenceSolution: """
            // iOS 17 — PreferenceKey + Color.clear
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
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: WidthKey.self, value: proxy.size.width)
                            }
                        )
                        .onPreferenceChange(WidthKey.self) { width = $0 }
                }
            }

            // iOS 18 — much simpler:
            // .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
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
            @State. The classic bug is `ForEach(items, id: \\.self)` on a \
            value type that mutates — identity churns and animations break. \
            Use a stable unique id (UUID, primary key) and reach for `.id()` \
            only when you intentionally want a remount (e.g., resetting a \
            form on user switch).
            """,
            starterCode: """
            ForEach(items, id: \\.self) { item in
                EditableRow(item: item) // @State inside resets unexpectedly
            }
            """,
            referenceSolution: """
            struct Item: Identifiable, Hashable {
                let id: UUID
                var title: String
            }

            ForEach(items) { item in           // uses Identifiable.id — stable
                EditableRow(item: item)
            }

            // Intentionally remount a screen on user switch:
            ProfileView(user: currentUser)
                .id(currentUser.id)
            """
        ),
        Question(
            id: 9,
            topic: .swiftUI,
            prompt: """
            You build a custom `RoundedShadowStyle` modifier you'll reuse across \
            many views. What's the right way to package it so it's both \
            ergonomic to call and parameterizable?
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
            composable, type-erased only at the boundary you want, and the \
            call-site reads `.roundedShadow(radius: 8)` like a built-in. \
            Avoid AnyView (kills the diffing cost benefits) and don't mistake \
            PreferenceKey (parent-bound communication) for styling.
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

            // Card().roundedShadow(radius: 8, corner: 12)
            """
        ),
        Question(
            id: 10,
            topic: .swiftUI,
            prompt: """
            Inside a SwiftUI `List`, you wire `.matchedGeometryEffect` to \
            animate a row expanding into a detail. The effect glitches. What's \
            the most common root cause?
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
            push to detail — the effect has nothing to interpolate to. Real \
            recipe: keep the source visible (overlay the detail above the \
            list with a ZStack + custom transition driven by a state var), \
            or use the iOS 18 zoom transition API.
            """,
            starterCode: """
            @Namespace private var ns
            // List row uses .matchedGeometryEffect(id: item.id, in: ns)
            // Pushed Detail uses the same id+ns — animation glitches.
            """,
            referenceSolution: """
            struct Gallery: View {
                @Namespace private var ns
                @State private var selected: Item?
                let items: [Item] = ...

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
        )
    ]

    // ===================================================================
    // MARK: Architecture
    // ===================================================================
    static let architecture: [Question] = [
        Question(
            id: 11,
            topic: .architecture,
            prompt: """
            Your team debates MVVM vs TCA for a new module. Which trade-off \
            best captures *when TCA is worth its overhead*?
            """,
            options: [
                "TCA is always better — it's the modern standard.",
                "TCA is worth it when you need exhaustive testability of complex state machines, deterministic effects, and a single source of truth for navigation/dependencies — at the cost of more boilerplate and a steeper learning curve. For simple CRUD screens, MVVM with @Observable is lighter.",
                "TCA only matters if you're building a multi-platform app (iOS+macOS+watchOS).",
                "MVVM cannot be tested; TCA is the only testable pattern."
            ],
            correctIndex: 1,
            explanation: """
            Senior interviewers want you to articulate trade-offs, not pick a \
            side. TCA's value: pure-function reducers, snapshot tests of \
            state transitions, dependency injection baked in, navigation as \
            data. Cost: more types per feature, more ceremony. For a settings \
            screen, it's overkill; for a complex chat app with offline + \
            presence + threading, the testability pays for itself.
            """,
            starterCode: """
            // Discuss: when would you reach for TCA over @Observable + MVVM?
            // (No code starter — interviewer wants reasoning here.)
            """,
            referenceSolution: """
            Decision matrix:

            REACH FOR TCA WHEN
            - State machine is complex (many events, transitions, side-effects).
            - You need replayable, snapshot-style tests of state evolution.
            - Multiple modules share a normalized navigation/identity model.
            - Effects must be deterministic and pluggable (DI, mocked clocks).

            STAY WITH MVVM (@Observable) WHEN
            - Screens are mostly CRUD over a network resource.
            - Team is unfamiliar with Composable architectures.
            - You can't justify the boilerplate (Action enum, Reducer, Store)
              for a screen with 3 buttons and 1 list.

            HYBRID
            - TCA for the trunk (navigation, auth, sync engine), MVVM leaves
              for individual feature screens — pragmatic and common in
              shipping teams.
            """
        ),
        Question(
            id: 12,
            topic: .architecture,
            prompt: """
            What's the cleanest way to inject dependencies (e.g., `APIClient`, \
            `AnalyticsService`) into SwiftUI views without resorting to \
            singletons or prop-drilling 8 layers deep?
            """,
            options: [
                "Singletons via `static let shared` — that's the SwiftUI way.",
                "Pass every dependency as an init parameter through every view.",
                "Use the `Environment` system: define `EnvironmentKey`s (or `@Entry` in iOS 18) for each service, inject at the top with `.environment(\\.api, prodAPI)`, override with mocks in previews/tests.",
                "Wrap each in `@StateObject` and rely on SwiftUI to discover them by type."
            ],
            correctIndex: 2,
            explanation: """
            Environment-based DI is the SwiftUI-native answer. It scales (no \
            prop-drilling), tests cleanly (override per-test), and integrates \
            with `#Preview { … }` (override with stubs). Singletons hide \
            dependencies and prevent test isolation; init-injection works but \
            forces every intermediate view to know about the service. iOS 18's \
            `@Entry` macro removes the EnvironmentKey boilerplate.
            """,
            starterCode: """
            protocol APIClient { func fetch() async throws -> [Post] }
            // TODO: wire APIClient through SwiftUI's environment.
            """,
            referenceSolution: """
            // iOS 17 style — explicit EnvironmentKey
            private struct APIClientKey: EnvironmentKey {
                static let defaultValue: any APIClient = LiveAPIClient()
            }
            extension EnvironmentValues {
                var api: any APIClient {
                    get { self[APIClientKey.self] }
                    set { self[APIClientKey.self] = newValue }
                }
            }

            // iOS 18 — @Entry shorthand
            // extension EnvironmentValues { @Entry var api: any APIClient = LiveAPIClient() }

            // Top of the app
            ContentView().environment(\\.api, LiveAPIClient())

            // In a deep view
            struct FeedView: View {
                @Environment(\\.api) private var api
                var body: some View { ... }
            }

            // In tests/previews
            #Preview { FeedView().environment(\\.api, MockAPIClient()) }
            """
        ),
        Question(
            id: 13,
            topic: .architecture,
            prompt: """
            You inherit a 2000-line `MasterViewController` (Massive View \
            Controller). You can't rewrite it in one go. What's a credible \
            *incremental* refactor sequence?
            """,
            options: [
                "Rewrite the whole thing in SwiftUI in a feature branch — ship in 3 months.",
                "Extract pure model/business logic into testable types first, then move side-effecting work behind protocols (DI), then introduce a coordinator/router for navigation, then progressively replace child views/cells with SwiftUI via `UIHostingController`.",
                "Add `// TODO: refactor` and move on — refactors are never worth the risk.",
                "Inherit from it and override every method — composition by inheritance."
            ],
            correctIndex: 1,
            explanation: """
            The strangler-fig pattern: harvest the testable nucleus first \
            (parsing, mapping, business rules), introduce protocol seams for \
            networking/persistence, peel navigation out into a coordinator, \
            then replace screens with SwiftUI bridged via UIHostingController. \
            This keeps the app shippable at every step — exactly what senior \
            interviewers want to hear since you'll be parachuted into a \
            client's existing codebase.
            """,
            starterCode: """
            // High-level sequence — describe in your own words.
            // Then show one concrete extraction.
            """,
            referenceSolution: """
            Step-by-step strangler-fig:

            1. Lift pure logic out of the VC.
               - Move data mapping, validation, formatting into structs/services.
               - Add unit tests on the extracted types — your safety net.

            2. Introduce protocol seams for I/O.
               - protocol APIClient, protocol Storage, protocol Analytics.
               - VC holds `let api: APIClient` (init-injected); production wires
                 the real impl, tests wire mocks.

            3. Coordinator/router for navigation.
               - Move `present`/`pushViewController` calls into a Coordinator
                 type. VC announces intents; coordinator decides routes.

            4. Bridge SwiftUI piece by piece.
               - Replace a child cell with SwiftUI via UIHostingConfiguration
                 (iOS 16+) or wrap a SwiftUI subview with UIHostingController.
               - Keep the parent VC; greenfield each leaf.

            5. Migrate the shell last.
               - Once 80% of children are SwiftUI, convert the container.

            Throughout: ship every step. Never long-lived branches.
            """
        ),
        Question(
            id: 14,
            topic: .architecture,
            prompt: """
            In an MVVM SwiftUI screen, where do you put navigation logic — in \
            the View, the ViewModel, or somewhere else?
            """,
            options: [
                "Always in the View — SwiftUI navigation IS view state.",
                "Always in the ViewModel — it owns all logic.",
                "Navigation *intent* (what to navigate to) belongs in the VM as state (e.g., `selectedItem: Item?` or `path: NavigationPath`), but the View binds that state to `NavigationStack`/`.sheet`. For multi-screen flows, lift the path into a coordinator/router.",
                "It doesn't matter — SwiftUI navigation is stateless."
            ],
            correctIndex: 2,
            explanation: """
            SwiftUI's data-driven navigation aligns naturally with MVVM: VM \
            holds the state (`@Observable var path: [Route] = []` or \
            `selected: Item?`), View binds. For flows that span multiple \
            screens / deep links, hoist the path into a Coordinator type \
            shared via Environment. Putting navigation purely in the View \
            scatters logic; putting UIKit-style "presentVC" calls in the VM \
            recreates the old MVC mess.
            """,
            starterCode: """
            @Observable
            final class FeedVM {
                var posts: [Post] = []
                // TODO: where does "show post detail" live?
            }
            """,
            referenceSolution: """
            @Observable
            final class FeedVM {
                var posts: [Post] = []
                var selected: Post?           // navigation state lives here
            }

            struct FeedView: View {
                @State private var vm = FeedVM()
                var body: some View {
                    NavigationStack {
                        List(vm.posts) { post in
                            Button(post.title) { vm.selected = post }
                        }
                        .navigationDestination(item: $vm.selected) { post in
                            PostDetailView(post: post)
                        }
                    }
                }
            }

            // For multi-step flows, a Router @Observable owns NavigationPath
            // and is injected via Environment.
            """
        ),
        Question(
            id: 15,
            topic: .architecture,
            prompt: """
            For a feature that fetches & caches data, which Clean-style \
            decomposition is appropriate, and what's the *one* layer juniors \
            most often skip?
            """,
            options: [
                "View → ViewModel → Repository → DataSources (remote + local). Juniors most often skip the **Repository**, leaking persistence/network details into the VM.",
                "View → ViewModel only — anything else is overengineering.",
                "View → Service Locator — singletons are fine if you wrap them.",
                "View → ViewModel → Network → Database directly — the Repository is unnecessary."
            ],
            correctIndex: 0,
            explanation: """
            Repository centralizes the cache-vs-network policy and exposes a \
            single domain-level API to the VM. Without it, VMs grow conditional \
            "if cached then... else fetch and write..." logic that's hard to \
            test and breaks when offline rules change. Senior interviewers \
            specifically probe whether you can name this layer and explain its \
            value — it's the single most-skipped abstraction in Clean.
            """,
            starterCode: """
            // Sketch the layers for a "PostsFeed" feature.
            """,
            referenceSolution: """
            // Domain model — pure
            struct Post: Identifiable { let id: UUID; let title: String }

            // Data sources — talk to one technology each
            protocol RemotePostsSource { func fetch() async throws -> [Post] }
            protocol LocalPostsSource  {
                func load() throws -> [Post]
                func save(_: [Post]) throws
            }

            // Repository — encodes cache policy, returns domain models
            protocol PostsRepository {
                func posts(forceRefresh: Bool) async throws -> [Post]
            }
            final class DefaultPostsRepository: PostsRepository {
                let remote: RemotePostsSource
                let local: LocalPostsSource
                init(remote: RemotePostsSource, local: LocalPostsSource) {
                    self.remote = remote; self.local = local
                }
                func posts(forceRefresh: Bool) async throws -> [Post] {
                    if !forceRefresh, let cached = try? local.load(), !cached.isEmpty {
                        return cached
                    }
                    let fresh = try await remote.fetch()
                    try? local.save(fresh)
                    return fresh
                }
            }

            // ViewModel — knows only the repository's domain API
            @Observable @MainActor
            final class FeedVM {
                let repo: PostsRepository
                var posts: [Post] = []
                init(repo: PostsRepository) { self.repo = repo }
                func load() async {
                    posts = (try? await repo.posts(forceRefresh: false)) ?? []
                }
            }
            """
        )
    ]

    // ===================================================================
    // MARK: Swift deep dive
    // ===================================================================
    static let swiftCore: [Question] = [
        Question(
            id: 16,
            topic: .swiftCore,
            prompt: """
            Pick the right return-type form for `func makeView() -> ??? where ??? \
            represents "any View"`. When do you choose `some View` vs `any View`?
            """,
            options: [
                "Always `any View`. `some View` is legacy.",
                "Always `some View`. `any View` doesn't compile.",
                "`some View` (opaque) when the *concrete* type is fixed but private — cheap, statically-dispatched, lets SwiftUI diff. `any View` (existential) only when the concrete type genuinely varies at runtime — boxes via existential container, more expensive.",
                "They're identical performance-wise; pick by taste."
            ],
            correctIndex: 2,
            explanation: """
            `some` is opaque: caller can't see the concrete type but the \
            compiler still knows it, so generics & associated types resolve \
            statically. `any` is an existential box that erases the type at \
            runtime; necessary if a single variable must hold heterogeneous \
            conformers (`var renderers: [any Renderer]`), but adds indirection. \
            In SwiftUI, almost always reach for `some View`. Use `any` only \
            when you genuinely need heterogeneity.
            """,
            starterCode: """
            // Two functions:
            func a() -> ??? { Text("hi") }                 // hidden concrete
            func b(...) -> ??? { Bool.random() ? Text("a") : Image(systemName: "x") } // varies
            """,
            referenceSolution: """
            // a) The concrete type is fixed (Text), just hidden — opaque.
            func a() -> some View { Text("hi") }

            // b) Two different concrete types depending on input — needs erasure.
            // Either AnyView (cheap escape hatch) or @ViewBuilder if the branches
            // share the same containing function:
            @ViewBuilder
            func b(_ flag: Bool) -> some View {
                if flag { Text("a") } else { Image(systemName: "x") }
            }
            // @ViewBuilder makes the return type a TupleView/ConditionalContent
            // — still `some View`, no AnyView needed.
            """
        ),
        Question(
            id: 17,
            topic: .swiftCore,
            prompt: """
            Inside a Combine `sink`, you write `self.value = newValue`. ARC: \
            does this leak, and why does the textbook fix specify `[weak self]` \
            but NOT `[unowned self]`?
            """,
            options: [
                "Doesn't leak — Combine breaks reference cycles automatically.",
                "Leaks because the closure captures `self` strongly, the AnyCancellable is owned by `self`, and the publisher chain holds the closure → cycle. Use `[weak self]`; `unowned` would crash if `self` deallocates before the publisher completes (e.g., view dismissed mid-stream).",
                "Use `[unowned self]` — it's faster and never crashes.",
                "Marking `self.value` as `@Published` removes the cycle."
            ],
            correctIndex: 1,
            explanation: """
            Cycle: publisher → closure → self → AnyCancellable → publisher. \
            `[weak self]` breaks the closure→self edge; `self?.value = ...` is \
            safe even if self is gone. `[unowned self]` would assume self \
            outlives the closure — but that's exactly the case publishers \
            violate when a view disappears mid-stream. Senior crash-budget \
            interview classic.
            """,
            starterCode: """
            final class VM {
                @Published var query = ""
                var bag = Set<AnyCancellable>()
                func bind() {
                    $query.sink { newValue in
                        self.value = newValue   // STRONG self captured
                    }.store(in: &bag)
                }
                var value = ""
            }
            """,
            referenceSolution: """
            final class VM {
                @Published var query = ""
                var bag = Set<AnyCancellable>()
                var value = ""
                func bind() {
                    $query.sink { [weak self] newValue in
                        self?.value = newValue
                    }.store(in: &bag)
                }
            }
            // Or even safer with .assign(to:):
            // $query.assign(to: &$value)   // built-in cycle-safe.
            """
        ),
        Question(
            id: 18,
            topic: .swiftCore,
            prompt: """
            A Swift `struct Document { var pages: [Page] /* huge */ }` is \
            passed by value all over the codebase. Why isn't this catastrophic \
            for memory, and what would force a copy?
            """,
            options: [
                "Swift secretly converts large structs to classes at compile time.",
                "`Array` and most stdlib collections are copy-on-write: assignments share storage by reference until *one side mutates*, only then a deep copy occurs. Mutation of a uniquely-referenced array stays in place.",
                "Structs are always lightweight; size doesn't matter.",
                "It IS catastrophic — always wrap large structs in a class."
            ],
            correctIndex: 1,
            explanation: """
            Copy-on-write (CoW) is implemented in `Array`, `Dictionary`, `Set`, \
            `String`, and you can build it yourself with `isKnownUniquelyReferenced`. \
            Assignment is O(1); a write triggers `_makeUniqueAndReserveCapacityIfNotUnique`, \
            cloning the buffer only if shared. Senior gotcha: if you pass an \
            array INTO a function that ONLY reads it, no copy happens; passing \
            it `inout` or mutating the parameter triggers CoW.
            """,
            starterCode: """
            // Build a custom CoW wrapper around a class-backed buffer.
            struct Buffer { /* backed by class storage, value semantics outside */ }
            """,
            referenceSolution: """
            final class Storage {
                var data: [Int]
                init(_ d: [Int]) { self.data = d }
                func clone() -> Storage { Storage(data) }
            }

            struct Buffer {
                private var storage: Storage

                init(_ data: [Int] = []) { self.storage = Storage(data) }

                var data: [Int] { storage.data }

                mutating func append(_ x: Int) {
                    if !isKnownUniquelyReferenced(&storage) {
                        storage = storage.clone()         // CoW kicks in
                    }
                    storage.data.append(x)
                }
            }

            // Now Buffer is a value type with class-backed storage — assignments
            // share, mutations clone exactly when needed.
            """
        ),
        Question(
            id: 19,
            topic: .swiftCore,
            prompt: """
            Generics with constraints vs protocols with associated types: when \
            does `func process<T: Equatable>(_ items: [T])` beat `func process(_ items: [any Equatable])`?
            """,
            options: [
                "They're identical.",
                "The generic version preserves T's identity across the function — you can compare two T's, return T, store T in a homogeneous collection. The existential `[any Equatable]` erases per-element type, so two elements aren't necessarily comparable to *each other*. Generics also enable static dispatch and zero-cost abstractions; existentials box.",
                "The existential version is always faster.",
                "Generics can't hold collections."
            ],
            correctIndex: 1,
            explanation: """
            `[any Equatable]` is a heterogeneous bag — each element is some \
            Equatable, but element 0 may be Int and element 1 String, so \
            `items[0] == items[1]` doesn't typecheck. The generic version \
            constrains all elements to the SAME T, unlocking comparisons and \
            return-type T. Plus static dispatch: no existential box, often \
            inlinable. Reach for `any` only when the heterogeneity is the \
            point.
            """,
            starterCode: """
            // Want a function that returns the first duplicate in an array.
            // Pick the right signature.
            func firstDuplicate(...) -> ???
            """,
            referenceSolution: """
            func firstDuplicate<T: Hashable>(_ items: [T]) -> T? {
                var seen = Set<T>()
                for item in items {
                    if !seen.insert(item).inserted { return item }
                }
                return nil
            }

            // [any Hashable] would NOT let us put items in Set<T>, because Set
            // needs a single Hashable type T at the type level. The generic
            // version is the correct tool.
            """
        ),
        Question(
            id: 20,
            topic: .swiftCore,
            prompt: """
            A Result Builder + property wrapper riddle. Why doesn't \
            `@Published var x = 0` work in a struct, and what's the deeper \
            constraint result builders share with property wrappers?
            """,
            options: [
                "Compiler bug — they should both work.",
                "`@Published` synthesizes a `projectedValue` of type `Publisher<Value, Never>` that needs reference-type backing storage to mutate consistently; structs have value semantics. Both result builders and property wrappers are *compile-time* desugaring tools — but @Published specifically requires a class because its publisher captures self.",
                "Structs cannot have any property wrappers.",
                "`@Published` requires `@MainActor`."
            ],
            correctIndex: 1,
            explanation: """
            The error message is "@Published is only available on properties of \
            classes." Reason: the synthesized publisher needs identity (it \
            outlives a single setter call and emits over time), and that demands \
            a reference. The deeper insight — both `@propertyWrapper` and \
            `@resultBuilder` are *compile-time* macros that desugar into \
            ordinary types; they're not runtime magic. Knowing the desugaring \
            (a property wrapper expands into `_x: Wrapper<Int>` + `x: Int { get/set }`) \
            is what separates senior from mid.
            """,
            starterCode: """
            struct Counter {
                @Published var count = 0   // ❌ won't compile
            }
            // Why? And how do you preserve the publisher pattern with a value type?
            """,
            referenceSolution: """
            // 1) Use a class for @Published:
            final class Counter: ObservableObject {
                @Published var count = 0
            }

            // 2) Or migrate to @Observable (Observation framework) which works
            // on classes via macro and is the modern path. Value types do NOT
            // get observation — observation is fundamentally tied to identity.

            // What @Published desugars to (mental model):
            // private var _count: Published<Int> = Published(initialValue: 0)
            // var count: Int { get { _count.value } set { _count.value = newValue } }
            // var $count: Publisher<Int, Never> { _count.projectedValue }
            //
            // The Published<Int> backing storage holds a CurrentValueSubject —
            // a class — that emits over time. That's why the enclosing type
            // must also be a class: the subject's identity must be stable.
            """
        )
    ]
}
