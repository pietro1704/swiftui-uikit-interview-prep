/*:
 # 03 — async/await + Structured Concurrency

 The biggest concurrency drill page. Coming from GCD, what bites senior
 devs hardest: (a) actor reentrancy, (b) Sendable, (c) MainActor
 isolation inheritance, (d) bounded TaskGroup, (e) cancellation
 propagation, (f) AsyncStream lifecycle.

 ----
 */
import Foundation

// MARK: - Drill 1: Where does Task { } actually run?

/*:
 ### Prompt 1 — bug-hunt
 GCD intuition: "spawn on a background queue."
 Swift Concurrency: "Task { ... } *inherits actor isolation from caller*."

 Will the `downloadGigantic()` below freeze the UI? Why? Fix without
 breaking actor isolation on `self.posts`.
 */

@MainActor
final class FeedVM_Buggy {
    var posts: [String] = []

    func downloadGigantic() -> Data { Data() } // pretend heavy
    func parse(_ d: Data) -> [String] { ["a"] }

    func reload() {
        Task {
            let data = downloadGigantic()    // <- runs WHERE?
            self.posts = parse(data)
        }
    }
}

// TODO: rewrite reload() so heavy work hops off main, results come back to main.

// MARK: - Drill 2: Actor reentrancy bug

/*:
 ### Prompt 2 — bug-hunt
 The actor below has a bug. Walk through (a) what's wrong, (b) how to
 fix without ditching the actor.

 **Hint**: actors serialize *single steps*, but they are REENTRANT —
 every `await` is a suspension point.
 */

actor BankAccount_Buggy {
    private var balance: Int = 100
    func costlyAuditCheck(amount: Int) async -> Bool {
        try? await Task.sleep(for: .milliseconds(50))
        return balance >= amount
    }
    func withdraw(_ amount: Int) async -> Bool {
        guard await costlyAuditCheck(amount: amount) else { return false }
        // BUG: between the await above and this line, a SECOND withdraw()
        //      call may have already changed `balance`.
        balance -= amount
        return true
    }
}

// TODO: Fix withdraw() so a second concurrent caller can't race the audit.

// MARK: - Drill 3: Bounded parallelism

/*:
 ### Prompt 3 — from-scratch
 "Download these 50 URLs, max 5 in flight." Top-of-mind question.

 GCD instinct: DispatchSemaphore + concurrentPerform.
 Swift Concurrency: TaskGroup that primes N tasks, then enqueues one
 more whenever one finishes via `await group.next()`.
 */

func downloadAll(_ urls: [URL]) async throws -> [Data] {
    // TODO: bounded parallelism, max 5 concurrent.
    return []
}

// MARK: - Drill 4: Sendable under Swift 6

/*:
 ### Prompt 4 — bug-hunt
 Compiler complains: "Capture of 'self' with non-Sendable type 'Cache'
 in a `@Sendable` closure." Cache is mutable. Three options.
 */

final class Cache_Buggy {
    var entries: [URL: Data] = [:]
}

// TODO: Show 3 options to make Cache safely cross actor boundaries.

// MARK: - Drill 5: AsyncStream + cancellation

/*:
 ### Prompt 5 — from-scratch
 Wrap a callback-based "tick every 500ms" timer as `AsyncStream<Int>`:
 - the consumer can cancel cleanly,
 - the producer stops emitting as soon as the consumer's Task is cancelled.
 */

func makeTicker() -> AsyncStream<Int> {
    // TODO
    AsyncStream { continuation in
        // start a timer
        // continuation.yield(...)
        // continuation.onTermination = { ... stop the timer ... }
    }
}

// MARK: - Drill 6: GlobalActor

/*:
 ### Prompt 6 — from-scratch
 Define a `@DatabaseActor` global actor and use it to isolate two
 unrelated types (a free function and a struct) on the same shared
 actor instance — without those types holding a reference to it.
 */

// TODO:
// 1. @globalActor actor DatabaseActor { static let shared = DatabaseActor() }
// 2. annotate a function and a struct with @DatabaseActor

// MARK: - Drill 7: isolated parameters

/*:
 ### Prompt 7 — from-scratch
 Write a free function `bump(_ counter: isolated Counter)` that
 increments the actor's counter without `await` inside.
 */

actor Counter {
    var value = 0
}

// TODO: func bump(_ counter: isolated Counter) { ... }

// MARK: - Drill 8: Task priority inheritance

/*:
 ### Prompt 8 — bug-hunt
 The intent below is "run heavyWork at low priority so UI stays
 responsive". But heavyWork ends up running at userInitiated priority.
 Why? Fix it.
 */

@MainActor
func startHeavyWork() {
    Task(priority: .background) {
        await heavyWork()   // actually runs at .userInitiated. Why?
    }
}

func heavyWork() async {}

// TODO: rewrite to genuinely run at .background.

// MARK: - Drill 9: AsyncSequence vs Combine

/*:
 ### Prompt 9 — from-scratch
 Solve the same problem two ways:
 (a) Combine pipeline: emit Int every second, take 5.
 (b) AsyncSequence: yield Int every second, take 5.

 Talk through the trade-offs.
 */

// TODO: write both versions.

// MARK: - Drill 10: Cancellation propagation

/*:
 ### Prompt 10 — bug-hunt
 The function below is "cancellable" (parent task gets cancelled), but
 the for-loop never observes it and runs to completion. Fix it.
 */

func computeAll(_ items: [Int]) async {
    for item in items {
        let result = expensiveCompute(item)
        print(result)
    }
}

func expensiveCompute(_ x: Int) -> Int {
    var s = 0; for _ in 0..<10_000_000 { s += x }; return s
}

// TODO: make computeAll observe cancellation.

// MARK: - Drill 11: async let lifetime

/*:
 ### Prompt 11 — bug-hunt
 Spot the issue: `async let banner = ...` is created but never awaited.
 What happens at the closing brace?
 */

func loadHomeScreen() async {
    async let banner = fetchBanner()    // never used!
    async let posts = fetchPosts()
    let p = await posts
    render(p)
}   // ← here, banner is auto-awaited; you pay for the call.

func fetchBanner() async -> String { "" }
func fetchPosts() async -> [String] { [] }
func render(_ posts: [String]) {}

// TODO: discuss the issue + fix it (drop async let or actually use the value).

// MARK: - Drill 12: MainActor in init

/*:
 ### Prompt 12 — from-scratch
 Make the @MainActor class below constructible from a non-MainActor
 context (e.g., from inside a background actor or Task.detached).
 */

@MainActor
final class FeedVM_12 {
    var posts: [String] = []
    let id: UUID

    init(id: UUID) {                   // forces caller onto MainActor
        self.id = id
    }
}

// TODO: rewrite init so it can be called from any context.

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1 -----
 // The buggy version: Task {} INSIDE a @MainActor class inherits MainActor.
 // So downloadGigantic() and parse() run on the MAIN THREAD → UI freezes.
 @MainActor
 final class FeedVM {
     var posts: [String] = []
     func reload() {
         Task {
             let posts: [String] = await Task.detached(priority: .userInitiated) {
                 let data = self.downloadGigantic()  // off main
                 return self.parse(data)
             }.value
             self.posts = posts                       // back on main
         }
     }
 }
 // Even cleaner: mark the heavy helpers `nonisolated` static so they don't
 // capture MainActor self.

 // ----- Drill 2 -----
 actor BankAccount {
     private var balance: Int = 100
     // Approach A: snapshot before await
     func withdraw(_ amount: Int) async -> Bool {
         let snapshot = balance
         guard snapshot >= amount else { return false }
         balance -= amount       // synchronous from snapshot — actor serializes
         return true
     }
 }

 // ----- Drill 3 -----
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

 // ----- Drill 4 -----
 // 1) Convert to actor (recommended).
 actor Cache {
     private var entries: [URL: Data] = [:]
     func get(_ url: URL) -> Data? { entries[url] }
     func set(_ data: Data, for url: URL) { entries[url] = data }
 }
 // 2) Make deep-immutable: final class with all `let` Sendable properties.
 //    Useful for snapshots, not for mutable caches.
 // 3) @unchecked Sendable + manual NSLock — last resort.
 //    final class LockedCache: @unchecked Sendable {
 //        private var entries: [URL: Data] = [:]
 //        private let lock = NSLock()
 //        func get(_ url: URL) -> Data? { lock.lock(); defer { lock.unlock() }; return entries[url] }
 //    }

 // ----- Drill 5 -----
 func makeTicker() -> AsyncStream<Int> {
     AsyncStream { continuation in
         let task = Task {
             var i = 0
             while !Task.isCancelled {
                 try? await Task.sleep(for: .milliseconds(500))
                 continuation.yield(i)
                 i += 1
             }
             continuation.finish()
         }
         continuation.onTermination = { _ in task.cancel() }
     }
 }

 // ----- Drill 6 -----
 @globalActor
 actor DatabaseActor {
     static let shared = DatabaseActor()
 }
 @DatabaseActor
 func runMigration() async { /* serialized on DatabaseActor */ }
 @DatabaseActor
 struct UserStore {
     func save(_ user: User) {}
     func load(id: UUID) -> User? { nil }
 }

 // ----- Drill 7 -----
 func bump(_ counter: isolated Counter) {
     counter.value += 1   // no `await` — already inside isolation
 }
 // Caller:  await bump(c)

 // ----- Drill 8 -----
 // Task priority is a "floor" — the runtime escalates to max(explicit,
 // inherited). To genuinely deprioritize, opt out of inheritance:
 @MainActor
 func startHeavyWork() {
     Task.detached(priority: .background) {
         await heavyWork()
     }
 }

 // ----- Drill 9 -----
 // Combine
 import Combine
 let cancel = Timer.publish(every: 1, on: .main, in: .common)
     .autoconnect()
     .scan(0) { acc, _ in acc + 1 }
     .prefix(5)
     .sink { print($0) }

 // Async
 for await tick in (0..<5).publisher.values {   // crude; real timing below
     try? await Task.sleep(for: .seconds(1))
     print(tick)
 }
 // Or via custom AsyncStream:
 //   for await n in tickerStream.prefix(5) { print(n) }

 // Trade-offs:
 //   Combine: push-based, multicast, rich operators, Cancellable lifecycle.
 //   AsyncSequence: pull-based, single-consumer, integrates with structured
 //                  cancellation (parent task cancel kills the loop).

 // ----- Drill 10 -----
 func computeAll(_ items: [Int]) async throws {
     for item in items {
         try Task.checkCancellation()    // throws CancellationError if cancelled
         let result = expensiveCompute(item)
         print(result)
     }
 }
 // Or `if Task.isCancelled { return }` if you don't want to throw.

 // ----- Drill 11 -----
 // The async let creates an implicit child task. Scope-end auto-awaits it
 // even if you never used the value. So:
 //  - fetchBanner() DOES run (paid for it).
 //  - scope end blocks until it completes.
 // Fix A: drop async let, use a fire-and-forget Task if truly optional:
 func loadHomeScreen() async {
     Task { _ = try? await fetchBanner() }   // unstructured — leaks scope
     let posts = await fetchPosts()
     render(posts)
 }
 // Fix B: actually use it
 func loadHomeScreen2() async {
     async let banner = fetchBanner()
     async let posts = fetchPosts()
     render(await posts)
     let _ = await banner
 }

 // ----- Drill 12 -----
 @MainActor
 final class FeedVM_12_Fixed {
     var posts: [String] = []
     let id: UUID
     nonisolated init(id: UUID) {
         self.id = id           // OK: only nonisolated state set here
     }
 }
 // Now FeedVM_12_Fixed(id: ...) is callable from anywhere. To touch
 // `posts` at startup, hop to MainActor:
 //   let vm = FeedVM_12_Fixed(id: id)
 //   Task { @MainActor in vm.posts = ["initial"] }

*/
