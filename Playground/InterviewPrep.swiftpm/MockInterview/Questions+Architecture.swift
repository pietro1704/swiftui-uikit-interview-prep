import Foundation

// 15 architecture questions covering: MVVM/TCA, DI, navigation, repositories,
// modularization, deep linking, factories, feature flags, observers, composition.

extension QuestionBank {
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
                "TCA is worth it when you need exhaustive testability of complex state machines, deterministic effects, and a single source of truth for navigation/dependencies — at the cost of more boilerplate. For simple CRUD screens, MVVM with @Observable is lighter.",
                "TCA only matters if you're building a multi-platform app.",
                "MVVM cannot be tested; TCA is the only testable pattern."
            ],
            correctIndex: 1,
            explanation: """
            Senior interviewers want trade-offs, not preferences. TCA's value: \
            pure-function reducers, snapshot tests of state, dependency \
            injection baked in, navigation as data. Cost: more types per \
            feature. For settings, overkill; for chat with offline + presence, \
            testability pays for itself.
            """,
            starterCode: """
            // Discuss: when would you reach for TCA over @Observable + MVVM?
            """,
            referenceSolution: """
            REACH FOR TCA WHEN:
            - Complex state machine (many events, transitions, effects).
            - You need replayable, snapshot-style state tests.
            - Multiple modules share normalized navigation/identity.
            - Effects must be deterministic and pluggable (DI, mocked clocks).

            STAY WITH MVVM (@Observable) WHEN:
            - Mostly CRUD over a network resource.
            - Team is unfamiliar with composable architectures.
            - Boilerplate (Action enum, Reducer, Store) doesn't justify itself.

            HYBRID: TCA for the trunk (auth, sync, navigation), MVVM leaves
            for individual feature screens.
            """
        ),
        Question(
            id: 12,
            topic: .architecture,
            prompt: """
            What's the cleanest way to inject dependencies (e.g., `APIClient`) \
            into SwiftUI views without singletons or prop-drilling?
            """,
            options: [
                "Singletons via `static let shared`.",
                "Pass every dependency as an init parameter through every view.",
                "Use the `Environment` system: define `EnvironmentKey`s (or `@Entry` in iOS 18) for each service, inject at the top, override in tests/previews.",
                "Wrap each in `@StateObject` and let SwiftUI discover them."
            ],
            correctIndex: 2,
            explanation: """
            Environment-based DI is the SwiftUI-native answer. Scales without \
            prop-drilling, tests cleanly, integrates with `#Preview`. \
            Singletons hide dependencies; init-injection forces every view to \
            know about the service. iOS 18's `@Entry` macro removes the \
            EnvironmentKey boilerplate.
            """,
            starterCode: """
            protocol APIClient { func fetch() async throws -> [Post] }
            // TODO: wire APIClient through the environment.
            """,
            referenceSolution: """
            // iOS 17:
            private struct APIClientKey: EnvironmentKey {
                static let defaultValue: any APIClient = LiveAPIClient()
            }
            extension EnvironmentValues {
                var api: any APIClient {
                    get { self[APIClientKey.self] }
                    set { self[APIClientKey.self] = newValue }
                }
            }
            // iOS 18:
            // extension EnvironmentValues { @Entry var api: any APIClient = LiveAPIClient() }

            ContentView().environment(\\.api, LiveAPIClient())
            struct FeedView: View {
                @Environment(\\.api) private var api
                var body: some View { ... }
            }
            #Preview { FeedView().environment(\\.api, MockAPIClient()) }
            """
        ),
        Question(
            id: 13,
            topic: .architecture,
            prompt: """
            You inherit a 2000-line `MasterViewController`. You can't rewrite \
            it in one go. What's a credible *incremental* refactor sequence?
            """,
            options: [
                "Rewrite the whole thing in SwiftUI in a feature branch.",
                "Extract pure model/business logic first, then move side-effecting work behind protocols (DI), introduce a coordinator/router, then progressively replace child views/cells with SwiftUI via UIHostingController.",
                "Add `// TODO: refactor` and move on.",
                "Inherit from it and override every method."
            ],
            correctIndex: 1,
            explanation: """
            Strangler-fig pattern: harvest the testable nucleus first, \
            introduce protocol seams for I/O, peel navigation out into a \
            coordinator, then replace screens with SwiftUI bridged via \
            UIHostingController. Keeps the app shippable at every step.
            """,
            starterCode: """
            // High-level sequence — describe in your own words.
            """,
            referenceSolution: """
            1. Lift pure logic out of the VC into structs/services.
               - Add unit tests on extracted types — your safety net.
            2. Introduce protocol seams for I/O.
               - protocol APIClient, Storage, Analytics; init-inject.
            3. Coordinator/router for navigation.
               - VC announces intents; coordinator decides routes.
            4. Bridge SwiftUI piece by piece (UIHostingConfiguration / UIHostingController).
            5. Migrate the shell last (≥80% children SwiftUI first).
            Throughout: ship every step. No long-lived branches.
            """
        ),
        Question(
            id: 14,
            topic: .architecture,
            prompt: """
            In an MVVM SwiftUI screen, where does navigation logic live — \
            View, ViewModel, or somewhere else?
            """,
            options: [
                "Always in the View.",
                "Always in the ViewModel.",
                "Navigation *intent* (what to navigate to) lives in the VM as state (e.g., `selected: Item?` or `path: NavigationPath`); View binds. For multi-screen flows, lift into a Coordinator/Router.",
                "It doesn't matter — SwiftUI navigation is stateless."
            ],
            correctIndex: 2,
            explanation: """
            Data-driven navigation aligns with MVVM: VM holds state, View \
            binds to NavigationStack/sheet/cover. For multi-step flows, hoist \
            the path into a Coordinator shared via Environment. Don't put \
            UIKit-style "presentVC" calls in the VM.
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
                            PostDetailView(post: post)
                        }
                    }
                }
            }
            // Multi-step flows: Router @Observable owns NavigationPath in Environment.
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
                "View → ViewModel only.",
                "View → Service Locator.",
                "View → ViewModel → Network → Database."
            ],
            correctIndex: 0,
            explanation: """
            Repository centralizes cache-vs-network policy and exposes a \
            domain-level API. Without it, VMs grow conditional logic that's \
            hard to test and breaks when offline rules change. Most-skipped \
            abstraction in Clean.
            """,
            starterCode: """
            // Sketch the layers for a "PostsFeed" feature.
            """,
            referenceSolution: """
            struct Post: Identifiable { let id: UUID; let title: String }
            protocol RemotePostsSource { func fetch() async throws -> [Post] }
            protocol LocalPostsSource { func load() throws -> [Post]; func save(_: [Post]) throws }
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
        ),

        // ==============================================================
        // NEW QUESTIONS — Q41–50
        // ==============================================================

        Question(
            id: 41,
            topic: .architecture,
            prompt: """
            What's the Coordinator pattern in SwiftUI, and is it still \
            relevant given NavigationStack(path:)?
            """,
            options: [
                "Coordinator is UIKit-only and obsolete in SwiftUI.",
                "It's still relevant for *multi-feature flows* — auth → home → profile, deep links, programmatic routing across modules. NavigationStack(path:) handles a single stack well, but a Router/Coordinator @Observable is the place where business logic decides routes (e.g., 'after login, push home; if first-time user, push onboarding').",
                "Coordinator only makes sense in TCA.",
                "It always adds boilerplate without value."
            ],
            correctIndex: 1,
            explanation: """
            NavigationStack(path:) replaces the *plumbing* the Coordinator \
            used to do in UIKit, but the *decisions* about where to route \
            still belong somewhere. A Router @Observable owns the path, \
            exposes intents (`.go(.profile(id))`), and is shared via \
            Environment. Useful when navigation crosses module boundaries \
            or depends on auth/feature-flag state.
            """,
            starterCode: """
            // Sketch a Router @Observable that owns NavigationPath.
            """,
            referenceSolution: """
            @Observable @MainActor
            final class Router {
                var path = NavigationPath()
                func go(_ route: Route) { path.append(route) }
                func backToRoot() { path = NavigationPath() }
            }

            struct App: App {
                @State private var router = Router()
                var body: some Scene {
                    WindowGroup {
                        NavigationStack(path: $router.path) {
                            HomeView()
                                .navigationDestination(for: Route.self) { route in
                                    routeView(for: route)
                                }
                        }
                        .environment(router)
                    }
                }
            }
            // Anywhere deep:
            //   @Environment(Router.self) private var router
            //   Button("Go") { router.go(.profile(id)) }
            """
        ),
        Question(
            id: 42,
            topic: .architecture,
            prompt: """
            "Offline-first" Repository: read flow vs write flow. What's the \
            usual difference in cache invalidation strategy?
            """,
            options: [
                "Reads and writes use the same cache policy.",
                "READS: serve from local cache first (fast UI), then refresh from remote in the background and update; user sees latest cached value instantly. WRITES: optimistic local update + queue the remote sync; on success, mark synced; on failure, rollback or retry. The asymmetry is the whole game.",
                "Writes always go remote-first, reads always go local.",
                "Both should be remote-first to maintain consistency."
            ],
            correctIndex: 1,
            explanation: """
            Offline-first is asymmetric. Reads optimize for *latency* (cache \
            first, refresh background). Writes optimize for *responsiveness* \
            (optimistic local mutation, queue + retry remote). Conflict \
            resolution lives in the repository, not the VM. Pattern hints: \
            CRDTs, last-write-wins, or domain-specific merge.
            """,
            starterCode: """
            protocol PostsRepository {
                func posts() -> AsyncStream<[Post]>     // streams as updates arrive
                func add(_ post: Post) async throws
            }
            // TODO: implement read = cache-then-network, write = optimistic.
            """,
            referenceSolution: """
            actor DefaultPostsRepository: PostsRepository {
                let remote: any RemoteSource
                let local: any LocalSource
                private var continuations: [AsyncStream<[Post]>.Continuation] = []

                func posts() -> AsyncStream<[Post]> {
                    AsyncStream { continuation in
                        Task {
                            // 1. emit cached immediately
                            if let cached = try? local.load() { continuation.yield(cached) }
                            // 2. fetch fresh
                            if let fresh = try? await remote.fetch() {
                                try? local.save(fresh)
                                continuation.yield(fresh)
                            }
                        }
                        await register(continuation)
                    }
                }

                func add(_ post: Post) async throws {
                    var local = try local.load()
                    local.append(post)
                    try self.local.save(local)        // optimistic
                    broadcast(local)
                    do {
                        try await remote.send(post)
                    } catch {
                        // rollback or queue retry
                        var rolled = try self.local.load()
                        rolled.removeAll { $0.id == post.id }
                        try self.local.save(rolled)
                        broadcast(rolled)
                        throw error
                    }
                }

                private func register(_ c: AsyncStream<[Post]>.Continuation) { continuations.append(c) }
                private func broadcast(_ posts: [Post]) { continuations.forEach { $0.yield(posts) } }
            }
            """
        ),
        Question(
            id: 43,
            topic: .architecture,
            prompt: """
            You need to build an `AnalyticsService` with two backends \
            (Firebase, Mixpanel) decided at runtime by a feature flag. Pick \
            the right pattern.
            """,
            options: [
                "Make `AnalyticsService` an enum with cases per backend.",
                "Define `protocol AnalyticsService` + concrete `FirebaseAnalytics`, `MixpanelAnalytics`, plus a `CompositeAnalytics` that fans out to both. Inject via Environment. Feature flag picks which composition is built at startup — the rest of the app sees one `any AnalyticsService`.",
                "Use Method Swizzling on UIApplication.",
                "Subclass FirebaseAnalytics and override methods to forward to Mixpanel."
            ],
            correctIndex: 1,
            explanation: """
            Composite + protocol + DI is the standard. The protocol stays \
            stable, you add backends as new conformers, and `CompositeAnalytics` \
            (an array of services) fans out — no caller changes. Feature flag \
            decides composition at startup. This is also how you'd add a \
            "no-op" analytics for tests/previews — `MockAnalytics()` in \
            `.environment(\\.analytics, MockAnalytics())`.
            """,
            starterCode: """
            // TODO: protocol AnalyticsService, two concretes, Composite.
            """,
            referenceSolution: """
            protocol AnalyticsService {
                func track(_ event: String, properties: [String: Any])
            }
            struct FirebaseAnalytics: AnalyticsService {
                func track(_ event: String, properties: [String: Any]) { /* ... */ }
            }
            struct MixpanelAnalytics: AnalyticsService {
                func track(_ event: String, properties: [String: Any]) { /* ... */ }
            }
            struct CompositeAnalytics: AnalyticsService {
                let services: [any AnalyticsService]
                func track(_ event: String, properties: [String: Any]) {
                    services.forEach { $0.track(event, properties: properties) }
                }
            }
            // At app startup:
            let analytics: any AnalyticsService = featureFlags.useDualPipeline
                ? CompositeAnalytics(services: [FirebaseAnalytics(), MixpanelAnalytics()])
                : FirebaseAnalytics()
            """
        ),
        Question(
            id: 44,
            topic: .architecture,
            prompt: """
            What's a "feature flag" architecture, and where do flags belong?
            """,
            options: [
                "Booleans scattered through `if` statements; that's enough.",
                "A `FeatureFlags` service (protocol + concrete fetched from remote config or A/B platform) injected via Environment. Code reads `flags.newCheckoutFlow` at decision points, not as a global. Decisions live at the *highest level you can defer them* — typically Router/Coordinator, or in Repository for behavior swaps.",
                "Feature flags should always be compile-time `#if`.",
                "They belong in UserDefaults, queried directly everywhere."
            ],
            correctIndex: 1,
            explanation: """
            Naive flags scatter `if` everywhere; modern pattern is a \
            FeatureFlags service: typed accessors, injected as a dependency, \
            backed by remote config (Firebase Remote Config, LaunchDarkly, \
            Statsig) plus a local fallback. Decisions live at the highest \
            level — usually Router (which screen to show) or Repository \
            (which backend to call). Testing wires a `MockFlags` with \
            specific values per test.
            """,
            starterCode: """
            // No code — sketch a typed FeatureFlags service.
            """,
            referenceSolution: """
            protocol FeatureFlags {
                var newCheckoutFlow: Bool { get }
                var maxRetries: Int { get }
                var experimentVariant: String? { get }
            }
            final class RemoteFeatureFlags: FeatureFlags { /* fetches from backend */ }
            struct StaticFeatureFlags: FeatureFlags {
                let newCheckoutFlow: Bool
                let maxRetries: Int
                let experimentVariant: String?
            }
            // In Environment:
            extension EnvironmentValues {
                @Entry var flags: any FeatureFlags = StaticFeatureFlags(
                    newCheckoutFlow: false, maxRetries: 3, experimentVariant: nil
                )
            }
            // Decision point:
            //   if flags.newCheckoutFlow { CheckoutV2View() } else { CheckoutV1View() }
            """
        ),
        Question(
            id: 45,
            topic: .architecture,
            prompt: """
            You modularize an app into 5 SPM packages: App, FeatureFeed, \
            FeatureProfile, Networking, Persistence. What's the rule about \
            inter-package dependencies?
            """,
            options: [
                "Any package can depend on any other.",
                "Strict layering: App → FeatureX → (Networking, Persistence). FeatureFeed must NEVER depend on FeatureProfile (sibling features are independent — they communicate via interfaces in App or a shared 'Domain' package). Cyclic dependencies between packages are a build-system error in SPM.",
                "Networking should depend on FeatureFeed for request types.",
                "Each feature should depend on every other feature for code sharing."
            ],
            correctIndex: 1,
            explanation: """
            Layering rules: features sit on top of infra (Networking, \
            Persistence, Domain). Features never import each other — that \
            recreates the monolith. Cross-feature communication: interfaces \
            in a shared package (`Coordinator`, `Domain`), or events/streams. \
            SPM enforces no cycles at the package level. This pays off in \
            build times AND testability — you can build/test FeatureFeed in \
            isolation.
            """,
            starterCode: """
            // No code — discuss + draw the dependency graph.
            """,
            referenceSolution: """
            App
              ├── FeatureFeed
              │   ├── Networking
              │   ├── Persistence
              │   └── Domain (shared models)
              ├── FeatureProfile
              │   ├── Networking
              │   ├── Persistence
              │   └── Domain
              ├── Networking
              ├── Persistence
              └── Domain

            // FeatureFeed and FeatureProfile NEVER import each other.
            // If they need to talk: events through the Router (in App),
            // or a shared protocol in Domain.
            //
            // Build-system benefits: changing FeatureProfile doesn't trigger
            // a rebuild of FeatureFeed.
            """
        ),
        Question(
            id: 46,
            topic: .architecture,
            prompt: """
            Deep linking: user taps `myapp://profile/abc123` in Mail. Where \
            does the URL get parsed, and how does it land in the right view?
            """,
            options: [
                "Each view checks the URL on appear.",
                "App-level handler (`.onOpenURL { url in ... }` or `UIApplicationDelegate`) parses the URL into a typed Route, then asks the Router to navigate. Parser is one place; routing is another. Views never see the URL.",
                "URLs go directly to the AppDelegate's `application(_:open:)` and you push a UIViewController.",
                "Deep links require a server round-trip."
            ],
            correctIndex: 1,
            explanation: """
            Two-layer pattern: \
            (1) URL parsing: `.onOpenURL` (or AppDelegate) → `DeepLinkParser` \
            converts a URL into a typed `Route` enum. \
            (2) Routing: pass that Route to a Router @Observable that knows \
            how to navigate (push, dismiss-and-push, switch tabs, etc.). \
            Views never see URLs. Same Router handles internal navigation, \
            so deep-link logic and tap-to-navigate share the same code path.
            """,
            starterCode: """
            enum Route: Hashable { case profile(String); case post(UUID) }
            // TODO: parse "myapp://profile/abc123" into Route.profile("abc123")
            // TODO: route to it via Router.
            """,
            referenceSolution: """
            struct DeepLinkParser {
                func route(from url: URL) -> Route? {
                    guard url.scheme == "myapp" else { return nil }
                    switch url.host {
                    case "profile":
                        let id = url.lastPathComponent
                        return .profile(id)
                    case "post":
                        guard let uuid = UUID(uuidString: url.lastPathComponent) else { return nil }
                        return .post(uuid)
                    default: return nil
                    }
                }
            }
            struct App: App {
                @State private var router = Router()
                var body: some Scene {
                    WindowGroup {
                        ContentView().environment(router)
                            .onOpenURL { url in
                                if let route = DeepLinkParser().route(from: url) {
                                    router.go(route)
                                }
                            }
                    }
                }
            }
            """
        ),
        Question(
            id: 47,
            topic: .architecture,
            prompt: """
            Three event-propagation tools — Combine `Publisher`, `AsyncStream`, \
            `NotificationCenter`. Pick the right one for: "the user pulled \
            their profile picture; downstream features need to refresh."
            """,
            options: [
                "NotificationCenter — it's a global event bus.",
                "Combine `Publisher` if other features are still using Combine; AsyncStream if you want structured concurrency. Either way, define a typed event in a shared module — never NotificationCenter (untyped, name collisions, lifecycle traps, opaque to grep).",
                "Both AsyncStream AND NotificationCenter for redundancy.",
                "There's no clean way to do this without a coordinator class."
            ],
            correctIndex: 1,
            explanation: """
            NotificationCenter is the wrong choice for typed event flow in \
            modern Swift: untyped userInfo dict, name-string collisions, \
            opaque dependency graph, observer-lifecycle pitfalls. Combine or \
            AsyncStream gives you typed events, structured cleanup, and \
            visible call sites. Pick AsyncStream for new code; Combine if \
            existing pipelines.
            """,
            starterCode: """
            // No code — discuss trade-offs + sketch a typed event bus.
            """,
            referenceSolution: """
            // Modern: a shared @Observable EventBus (or actor with AsyncStream)
            // exposed via Environment.
            actor UserEventBus {
                private var continuations: [AsyncStream<UserEvent>.Continuation] = []
                func events() -> AsyncStream<UserEvent> {
                    AsyncStream { c in
                        continuations.append(c)
                    }
                }
                func emit(_ event: UserEvent) {
                    continuations.forEach { $0.yield(event) }
                }
            }
            enum UserEvent { case avatarChanged(URL); case nameChanged(String) }

            // Consumer in another feature:
            //   .task {
            //     for await event in await bus.events() {
            //       if case .avatarChanged = event { refresh() }
            //     }
            //   }
            """
        ),
        Question(
            id: 48,
            topic: .architecture,
            prompt: """
            Composition vs inheritance for a `BaseViewController` shared \
            across 30 screens. The senior interviewer asks: would you keep \
            it, refactor, or delete?
            """,
            options: [
                "Keep it — it saves boilerplate.",
                "Refactor toward composition: extract the BaseVC's responsibilities into focused services (LoadingPresenter, ErrorBanner, AnalyticsTracker) that any VC composes via init or property; delete the inheritance. Inheritance hierarchies grow into 'God classes' — composition stays flat and testable.",
                "Inherit MORE deeply — make BaseVC2, BaseVC3.",
                "Convert all 30 screens to SwiftUI overnight."
            ],
            correctIndex: 1,
            explanation: """
            Inheritance defaults to coupling. A BaseVC that `view`s grow into \
            it accumulates responsibilities (loading state, error banners, \
            analytics, theming) — every subclass inherits everything, even \
            irrelevant pieces. Composition: extract each responsibility into \
            a service object, inject it. Each VC composes only what it needs. \
            Same logic transfers to SwiftUI ViewModifiers + Environment.
            """,
            starterCode: """
            // No code — sketch the composition refactor.
            """,
            referenceSolution: """
            // Before:
            class BaseVC: UIViewController {
                func showLoading() { ... }
                func showError(_ e: Error) { ... }
                func trackEvent(_ name: String) { ... }
            }
            // 30 subclasses inherit ALL three, even those that never load anything.

            // After (composition):
            protocol LoadingPresenter { func show(); func hide() }
            protocol ErrorPresenter { func present(_ error: Error) }
            protocol Analytics { func track(_ event: String) }

            final class FeedVC: UIViewController {
                let loading: any LoadingPresenter
                let errors: any ErrorPresenter
                let analytics: any Analytics
                init(loading: any LoadingPresenter, errors: any ErrorPresenter, analytics: any Analytics) {
                    self.loading = loading; self.errors = errors; self.analytics = analytics
                    super.init(nibName: nil, bundle: nil)
                }
                required init?(coder: NSCoder) { fatalError() }
            }
            // Now FeedVC composes only what it uses; testing wires mocks.
            """
        ),
        Question(
            id: 49,
            topic: .architecture,
            prompt: """
            "Pure" reducer vs side-effecting reducer (TCA / Redux-style). \
            What's pure, and why does it matter?
            """,
            options: [
                "Same thing.",
                "A pure reducer is `(State, Action) -> State` with no I/O — given the same inputs, it ALWAYS returns the same state. Side effects (network, storage) are returned as separate `Effect` values that the runtime handles. Why: pure reducers are unit-testable as a function (no mocks); state evolution is replayable; debug tools can step through state changes.",
                "Pure reducers run on the main thread; impure ones run in background.",
                "Pure means 'with no Combine' and impure means 'with Combine'."
            ],
            correctIndex: 1,
            explanation: """
            The discipline: state machine = pure. Effects = data values \
            describing 'what to do next' (fetch, write, schedule), executed \
            by a runtime. Tests look like: \
            `XCTAssertEqual(reducer(state, .tapButton), .loading)` — no mocks. \
            Replay/time-travel debugging falls out for free.
            """,
            starterCode: """
            enum Action { case tapLogin; case loginSucceeded(User); case loginFailed(Error) }
            struct State { var isLoading = false; var user: User? }
            // TODO: pure reducer + Effect representation
            """,
            referenceSolution: """
            enum Effect {
                case authenticate(username: String, password: String)
                case none
            }
            func reduce(state: inout State, action: Action) -> Effect {
                switch action {
                case .tapLogin:
                    state.isLoading = true
                    return .authenticate(username: "u", password: "p")
                case .loginSucceeded(let user):
                    state.isLoading = false
                    state.user = user
                    return .none
                case .loginFailed:
                    state.isLoading = false
                    return .none
                }
            }
            // The runtime turns Effect into actual async calls.
            // Tests: feed (state, action), assert new state — no mocks.
            """
        ),
        Question(
            id: 50,
            topic: .architecture,
            prompt: """
            Your team has 3 navigation stacks: Tab1, Tab2, Tab3 (TabView). A \
            push notification opens the app and needs to go to a specific \
            screen in Tab2, even if Tab1 was selected. How do you architect this?
            """,
            options: [
                "Hardcode `selectedTab = 1` and push the screen.",
                "A Router @Observable holds: (a) `selectedTab: TabIdentifier`, (b) per-tab `path: NavigationPath` dict. Notification handler updates BOTH: switches tab AND appends to that tab's path. View binds tab + each NavigationStack to its slice of router state.",
                "Use UIApplication.shared.open with a URL.",
                "Persist navigation state to disk and reboot the app."
            ],
            correctIndex: 1,
            explanation: """
            For multi-stack navigation, the Router holds tab selection AND \
            per-tab paths. Notifications, deep links, and code-driven \
            navigation all funnel through the same Router intents. Each \
            NavigationStack binds to its tab's path. Tab change preserves \
            the inner stacks (paths persist per tab) — no flicker.
            """,
            starterCode: """
            enum Tab: Hashable { case feed, search, profile }
            // TODO: Router with selectedTab + per-tab paths
            """,
            referenceSolution: """
            @Observable @MainActor
            final class Router {
                var selectedTab: Tab = .feed
                var paths: [Tab: NavigationPath] = [.feed: .init(), .search: .init(), .profile: .init()]
                func go(_ tab: Tab, route: Route) {
                    selectedTab = tab
                    paths[tab, default: .init()].append(route)
                }
            }
            struct AppView: View {
                @State private var router = Router()
                var body: some View {
                    TabView(selection: $router.selectedTab) {
                        NavigationStack(path: Binding(
                            get: { router.paths[.feed] ?? .init() },
                            set: { router.paths[.feed] = $0 }
                        )) { FeedRoot() }
                        .tag(Tab.feed)
                        // ... same for search/profile
                    }
                    .environment(router)
                }
            }
            // Notification handler: router.go(.profile, route: .post(id))
            """
        )
    ]
}
