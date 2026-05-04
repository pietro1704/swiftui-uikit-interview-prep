import Foundation

// 15 concurrency questions covering: actor isolation, reentrancy, Sendable,
// structured concurrency, AsyncStream, GlobalActor, cancellation, priorities.

extension QuestionBank {
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
            `Task.detached { }` opts out of inheritance.
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
                var posts: [Post] = []
                static let url = URL(string: "https://api.example.com/feed")!
                func reload() {
                    Task {
                        let posts = try await Task.detached(priority: .userInitiated) {
                            let (data, _) = try await URLSession.shared.data(from: Self.url)
                            return try JSONDecoder().decode([Post].self, from: data)
                        }.value
                        self.posts = posts
                    }
                }
            }
            """
        ),
        Question(
            id: 2,
            topic: .concurrency,
            prompt: """
            An `actor BankAccount { var balance: Int; func deposit(_ n: Int) async }` \
            calls `await audit.log(balance)` mid-method. After the await resumes, \
            `balance` may differ from what you observed before. Why?
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
            messages may execute. Don't assume invariants across awaits.
            """,
            starterCode: """
            actor BankAccount {
                var balance: Int = 0
                func deposit(_ amount: Int, audit: Auditor) async {
                    balance += amount
                    await audit.log(balance)
                    print("New balance is", balance)
                }
            }
            """,
            referenceSolution: """
            actor BankAccount {
                var balance: Int = 0
                func deposit(_ amount: Int, audit: Auditor) async {
                    balance += amount
                    let snapshot = balance
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
            Start N, then start one more for each finished — that's the recipe.
            """,
            starterCode: """
            func downloadAll(_ urls: [URL]) async throws -> [Data] {
                fatalError("implement bounded parallelism, max 5 concurrent")
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
            an actor boundary without an explicit `@unchecked Sendable` or redesign?
            """,
            options: [
                "`struct User { let id: UUID; let name: String }`",
                "`final class Snapshot { let id: UUID; let frozen: [String: Int] }` (all `let`, deep-immutable)",
                "`final class Cache { var entries: [URL: Data] = [:] }` — mutable class without synchronization.",
                "An `enum Status { case idle, loaded(Int) }` with no associated reference types."
            ],
            correctIndex: 2,
            explanation: """
            Sendable is automatic for value types whose properties are Sendable, \
            and for `final` classes with all `let` Sendable properties. A \
            mutable reference-type cache has no synchronization the compiler \
            can prove safe — wrap in actor, make deep-immutable, or annotate \
            `@unchecked Sendable` after adding manual locking.
            """,
            starterCode: """
            final class Cache {
                var entries: [URL: Data] = [:]
            }
            """,
            referenceSolution: """
            actor Cache {
                private var entries: [URL: Data] = [:]
                func get(_ url: URL) -> Data? { entries[url] }
                func set(_ data: Data, for url: URL) { entries[url] = data }
            }
            """
        ),
        Question(
            id: 5,
            topic: .concurrency,
            prompt: """
            A consumer wraps a delegate-callback API as `AsyncStream`. The screen \
            disappears mid-stream. What's the minimum required to avoid a leak \
            and silent zombie producer?
            """,
            options: [
                "Nothing — `AsyncStream` self-terminates when no consumer awaits it.",
                "Hold the producing `Task` and call `.cancel()` in `onDisappear`; the stream's `onTermination` should release the delegate.",
                "Switch to `AsyncThrowingStream` — only that variant can be cancelled.",
                "Use `[weak self]` in the consumer; the framework cancels orphan streams automatically."
            ],
            correctIndex: 1,
            explanation: """
            AsyncStream does NOT auto-terminate — its continuation keeps the \
            producer alive until you `finish()` or cancel the consuming task. \
            Pattern: store consumer Task, cancel in `onDisappear`, use \
            `continuation.onTermination` inside the stream to detach.
            """,
            starterCode: """
            final class LocationFeed {
                func stream() -> AsyncStream<CLLocation> {
                    AsyncStream { continuation in
                        // TODO: forward delegate updates; clean up on termination
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
            """
        ),

        // ==============================================================
        // NEW QUESTIONS — Q21–30
        // ==============================================================

        Question(
            id: 21,
            topic: .concurrency,
            prompt: """
            You define `@globalActor actor DatabaseActor { static let shared = DatabaseActor() }`. \
            What's the practical *win* over a plain `actor Database`?
            """,
            options: [
                "Faster execution — global actors compile to lock-free code.",
                "You can annotate ANY type or function with `@DatabaseActor` to mark it as isolated to that single actor instance, even if it's nominally a struct, enum, function, or property — without those types holding a reference to the actor.",
                "It removes the need for `await` when calling its methods.",
                "Global actors automatically replace `@MainActor` for all UI code."
            ],
            correctIndex: 1,
            explanation: """
            A global actor is a singleton actor whose isolation can be applied \
            *as an attribute* anywhere in your codebase. `@MainActor` itself is \
            a global actor. The point: make a *family* of types share isolation \
            without each carrying a reference. Useful for DB layers where \
            many functions/types must serialize on one queue.
            """,
            starterCode: """
            @globalActor
            actor DatabaseActor {
                static let shared = DatabaseActor()
            }

            // TODO: annotate a free function and a struct as @DatabaseActor
            """,
            referenceSolution: """
            @globalActor
            actor DatabaseActor {
                static let shared = DatabaseActor()
            }

            @DatabaseActor
            func runMigration() async { /* serialized on DatabaseActor */ }

            @DatabaseActor
            struct UserStore {
                func save(_ user: User) { /* isolated */ }
                func load(id: UUID) -> User? { nil }
            }

            // Caller must `await` to cross into DatabaseActor isolation:
            //   await runMigration()
            //   let store = UserStore(); await store.save(user)
            """
        ),
        Question(
            id: 22,
            topic: .concurrency,
            prompt: """
            What does the `isolated` keyword in `func reload(on actor: isolated MyActor)` do, \
            and when would you reach for it?
            """,
            options: [
                "It marks the parameter as `inout` so the actor's state can be mutated.",
                "It says: this function executes *as if it were a method of the passed actor* — no extra hop, no `await` needed when accessing that actor's state inside the body. Useful for free functions that operate on actor state without becoming actor methods.",
                "It enforces that only one caller at a time can pass this actor — like a mutex.",
                "It's a deprecated synonym for `@MainActor`."
            ],
            correctIndex: 1,
            explanation: """
            `isolated` parameters let a function "borrow" an actor's isolation \
            without being a method of that actor. Calling such a function is \
            an `await` (you cross into the actor), but inside the function you \
            access the actor's internals directly. Helps when refactoring a \
            big actor into smaller pieces while keeping invariants on shared state.
            """,
            starterCode: """
            actor Counter { var value = 0 }

            // TODO: write a free function that increments a counter,
            // takes the actor as an `isolated` parameter, and DOESN'T need await internally.
            """,
            referenceSolution: """
            actor Counter { var value = 0 }

            func bump(_ counter: isolated Counter) {
                counter.value += 1   // no `await` — we're already inside isolation
            }

            // Call site:
            //   let c = Counter()
            //   await bump(c)       // single hop into Counter, then synchronous body
            """
        ),
        Question(
            id: 23,
            topic: .concurrency,
            prompt: """
            You spawn `Task(priority: .background) { await heavyWork() }` from a \
            `@MainActor` function that's running at user-initiated priority. \
            What priority does the new task actually have?
            """,
            options: [
                ".background, always — you set it explicitly.",
                "Whichever is HIGHER between the explicit priority and the inherited caller priority — the runtime escalates to the higher of the two.",
                ".userInitiated — Task always inherits, never overrides.",
                "Undefined; depends on the scheduler."
            ],
            correctIndex: 1,
            explanation: """
            Task priority works like a "floor": the runtime takes the max of \
            (explicit priority, inherited priority). Setting `.background` \
            inside a `.userInitiated` context still runs at userInitiated, to \
            avoid priority inversion. To genuinely deprioritize, use \
            `Task.detached(priority: .background)` (which doesn't inherit).
            """,
            starterCode: """
            @MainActor
            func startWork() {
                Task(priority: .background) {  // priority = ?
                    await heavyWork()
                }
            }
            """,
            referenceSolution: """
            // To genuinely run at .background, opt out of inheritance:
            @MainActor
            func startWork() {
                Task.detached(priority: .background) {
                    await heavyWork()
                }
            }

            // Talk-track: priority escalation is INTENTIONAL — prevents priority
            // inversion (high-pri code waiting on low-pri data). Detached opts
            // out, but you also lose actor isolation, task locals, cancellation tree.
            """
        ),
        Question(
            id: 24,
            topic: .concurrency,
            prompt: """
            When should you reach for `AsyncSequence` instead of a Combine `Publisher`?
            """,
            options: [
                "Never — Combine is always more powerful.",
                "AsyncSequence is the right primitive when consumers want a `for await` loop with structured-concurrency semantics (cancellation, back-pressure via cooperative pull, no buffer); Combine is better when you need rich operator composition (combineLatest, zip, debounce out-of-the-box) and multiple subscribers.",
                "Always — Combine is being deprecated in iOS 18.",
                "Only on visionOS — AsyncSequence is platform-locked."
            ],
            correctIndex: 1,
            explanation: """
            They cover overlapping but distinct ground. AsyncSequence: pull-based, \
            single-consumer, integrates with structured cancellation. Combine: \
            push-based, multicast easy, huge operator catalog. Apple is adding \
            async-aware operators (Observation framework, AsyncAlgorithms package) \
            but Combine isn't deprecated — pick by use-case.
            """,
            starterCode: """
            // The same problem solved two ways:
            // (a) Combine pipeline that emits Int every second, take 5
            // (b) AsyncSequence that yields Int every second, take 5
            """,
            referenceSolution: """
            // Combine
            import Combine
            let sub = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .scan(0) { acc, _ in acc + 1 }
                .prefix(5)
                .sink { print($0) }

            // Async
            for await tick in (0..<5).async {
                try await Task.sleep(for: .seconds(1))
                print(tick)
            }
            // Or via AsyncStream:
            // for await n in tickStream.prefix(5) { print(n) }
            """
        ),
        Question(
            id: 25,
            topic: .concurrency,
            prompt: """
            A parent task spawns 3 child tasks via `withTaskGroup`. The user dismisses \
            the screen, which cancels the parent. What happens to the 3 children?
            """,
            options: [
                "Nothing — children outlive the parent and complete independently.",
                "All 3 are *implicitly* cancelled (`Task.isCancelled` becomes true). They keep RUNNING until they observe cancellation — the runtime never force-kills a task.",
                "The parent waits indefinitely until they finish.",
                "An error is thrown immediately at the cancel point, killing them."
            ],
            correctIndex: 1,
            explanation: """
            Cancellation in Swift Concurrency is COOPERATIVE: a cancel just \
            sets a flag. Child tasks need to check `Task.isCancelled` or call \
            cancellation-aware APIs (`Task.checkCancellation()`, `Task.sleep`, \
            networking with cancellation support) to react. CPU-bound loops \
            with no checks will run to completion despite "being cancelled".
            """,
            starterCode: """
            // BUG: this loop ignores cancellation completely.
            func computeAll(_ items: [Int]) async {
                for item in items {
                    let result = expensiveCompute(item)
                    print(result)
                }
            }
            """,
            referenceSolution: """
            func computeAll(_ items: [Int]) async throws {
                for item in items {
                    try Task.checkCancellation()   // throws CancellationError if cancelled
                    let result = expensiveCompute(item)
                    print(result)
                }
            }
            // Or: `if Task.isCancelled { return }` if you don't want to throw.
            """
        ),
        Question(
            id: 26,
            topic: .concurrency,
            prompt: """
            Spot the bug: `async let a = fetch(); doStuff()` — without ever using `a`.
            """,
            options: [
                "Nothing wrong, the unused result is fine.",
                "The compiler warns about unused result; the network call still completes in the background.",
                "`async let` requires the value to be awaited or explicitly cancelled before scope exit. The implicit await at scope end *will* run — so `fetch()` does happen, but you're paying for a value you don't use AND you block scope exit until it finishes.",
                "It causes a runtime crash."
            ],
            correctIndex: 2,
            explanation: """
            `async let` creates an implicit child task. At the end of its scope \
            (function/block), the runtime *auto-awaits* unused async lets to \
            preserve structured concurrency. So you pay the cost. To opt out, \
            await it manually with a discard, or restructure to a regular `Task` \
            you can ignore. Watch this in code review.
            """,
            starterCode: """
            func loadHomeScreen() async {
                async let banner = fetchBanner()    // never used!
                async let posts = fetchPosts()
                let p = await posts
                render(p)
            }   // ← here, banner is auto-awaited
            """,
            referenceSolution: """
            // Option A: drop async let, use a fire-and-forget Task if truly optional
            func loadHomeScreen() async {
                Task { _ = try? await fetchBanner() }   // not awaited, scope-leaks intentionally
                let posts = await fetchPosts()
                render(posts)
            }
            // Option B: actually use the value
            func loadHomeScreen() async {
                async let banner = fetchBanner()
                async let posts = fetchPosts()
                render(await posts, banner: try? await banner)
            }
            """
        ),
        Question(
            id: 27,
            topic: .concurrency,
            prompt: """
            Can you deadlock with Swift Concurrency the way you can with GCD?
            """,
            options: [
                "Yes — same deadlock semantics as GCD.",
                "Mostly NO — there are no blocking primitives, so a thread can't be held forever. But you CAN still create logical deadlocks: e.g., two actors awaiting each other in a cycle, or an actor awaiting itself reentrantly with state preconditions that no other call will satisfy.",
                "Only on macOS, never on iOS.",
                "Only when using `DispatchSemaphore` from inside an actor."
            ],
            correctIndex: 1,
            explanation: """
            Cooperative scheduling means threads aren't blocked — they're \
            reused for ready work. So classic GCD deadlocks (sync on a queue \
            you're already on) don't exist the same way. But you can still \
            build a logical wait cycle: A awaits B, B awaits A; or an actor \
            method awaits an external service that calls back into the actor \
            for a precondition that won't be met until the original call \
            completes. Reentrancy bites again.
            """,
            starterCode: """
            // No code — verbal answer in the interview.
            // Discuss: cooperative scheduling, lack of blocking primitives,
            // how logical wait-cycles can still occur.
            """,
            referenceSolution: """
            // Pseudo-deadlock to whiteboard:
            //
            // actor A {
            //     let b: B
            //     func ping() async { await b.pong() }   // <-- waits for B
            // }
            // actor B {
            //     let a: A
            //     func pong() async { await a.ping() }   // <-- waits for A
            // }
            //
            // Calling A.ping() now suspends forever. The threads aren't
            // blocked (cooperative), but progress is impossible — same effect
            // as a deadlock from the user's POV.
            //
            // Avoidance: invariant — actors don't call back across boundaries
            // synchronously; pass data via Sendable, not method calls.
            """
        ),
        Question(
            id: 28,
            topic: .concurrency,
            prompt: """
            What's the difference between `AsyncStream` and `AsyncThrowingStream`?
            """,
            options: [
                "AsyncThrowingStream is for I/O only.",
                "AsyncThrowingStream's iterator's `next()` is `throws` — the stream can finish with an error AND that error propagates up to the consumer's `for try await` loop. AsyncStream completes silently with `finish()`; consumers can't distinguish completion from an upstream error.",
                "They're identical, with different names for documentation purposes.",
                "AsyncThrowingStream supports cancellation; AsyncStream doesn't."
            ],
            correctIndex: 1,
            explanation: """
            Use AsyncThrowingStream when the producer can fail (network, file, \
            decoding) and you want consumers to handle the error in the same \
            place they consume values. Use plain AsyncStream when the source \
            is infallible (UI events, sensor readings) — keeps consumer code \
            simpler with `for await`.
            """,
            starterCode: """
            // No code — verbal answer.
            """,
            referenceSolution: """
            // Producer with potential failure:
            func bytes() -> AsyncThrowingStream<UInt8, Error> {
                AsyncThrowingStream { continuation in
                    do {
                        for byte in try readSomeBytes() {
                            continuation.yield(byte)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }

            // Consumer:
            do {
                for try await byte in bytes() { handle(byte) }
            } catch {
                showError(error)
            }
            """
        ),
        Question(
            id: 29,
            topic: .concurrency,
            prompt: """
            Inside an `@MainActor` class, can the `init` itself be `nonisolated` \
            — and why would you want that?
            """,
            options: [
                "No — init must always be MainActor.",
                "Yes: marking `nonisolated init(...)` lets you construct the object from a non-MainActor context (e.g., a background actor). The body of the init can only touch nonisolated state during construction — to set MainActor-isolated stored properties, you need them to have nonisolated default values or be wrapped (e.g., `Task { @MainActor in ... }` after construction).",
                "Yes, but only on Swift 6.0 exact.",
                "Only structs can have nonisolated init, never classes."
            ],
            correctIndex: 1,
            explanation: """
            `nonisolated init` is a real escape hatch. Without it, every caller \
            of init has to be on MainActor. With it, you can construct from a \
            background context — but you can only initialize stored properties \
            with nonisolated values. To set MainActor state at startup, hop \
            to MainActor in a `Task { @MainActor in ... }` after init. Common \
            for VMs created in background pipelines.
            """,
            starterCode: """
            @MainActor
            final class FeedVM {
                var posts: [Post] = []      // MainActor-isolated
                let id: UUID                // OK: stored let

                init(id: UUID) { self.id = id }   // forces caller onto MainActor
            }
            """,
            referenceSolution: """
            @MainActor
            final class FeedVM {
                var posts: [Post] = []
                let id: UUID

                nonisolated init(id: UUID) {
                    self.id = id           // OK: only nonisolated state set here
                }
            }

            // Now this works from any context:
            //   await Task.detached { _ = FeedVM(id: .init()) }
            //
            // To touch posts at startup:
            //   let vm = FeedVM(id: .init())
            //   Task { @MainActor in vm.posts = [...] }
            """
        ),
        Question(
            id: 30,
            topic: .concurrency,
            prompt: """
            `withDiscardingTaskGroup` (Swift 5.9+) vs `withTaskGroup` — what problem \
            does the discarding variant solve?
            """,
            options: [
                "Memory: regular TaskGroup retains ALL child task results in an internal buffer until you drain them. For long-running fan-out (e.g., processing a stream of 10,000 work items), that buffer grows unboundedly. `withDiscardingTaskGroup` discards results as tasks finish — no buffer growth.",
                "It runs faster on Apple Silicon.",
                "It cancels children automatically; the regular variant doesn't.",
                "It's the same; `withDiscardingTaskGroup` is just a syntactic alias."
            ],
            correctIndex: 0,
            explanation: """
            Classic TaskGroup is a queue that buffers child results until the \
            consumer reads them. For server-style fan-out (every event spawns \
            a task), this is a memory leak waiting to happen. \
            `withDiscardingTaskGroup` is purpose-built for fire-and-forget \
            child tasks where you don't care about return values — added in \
            Swift 5.9 specifically for this scaling case.
            """,
            starterCode: """
            // BUG: as `events` grows, memory usage grows with it.
            func process(events: AsyncStream<Event>) async {
                await withTaskGroup(of: Void.self) { group in
                    for await event in events {
                        group.addTask { await handle(event) }
                    }
                }
            }
            """,
            referenceSolution: """
            func process(events: AsyncStream<Event>) async {
                await withDiscardingTaskGroup { group in
                    for await event in events {
                        group.addTask { await handle(event) }
                    }
                }
            }
            // Same fan-out, no internal buffer — task results are dropped on
            // completion. Use this for any unbounded fan-out where you don't
            // need a value back. For collecting results, stick with
            // withTaskGroup but add structural backpressure (e.g., bounded
            // queue feeding addTask).
            """
        )
    ]
}
