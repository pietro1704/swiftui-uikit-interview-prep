/*:
 # 03 — async/await + Structured Concurrency

 You said this is a focus area. Coming from GCD, the things that bite
 senior devs hardest are: (a) actor reentrancy, (b) Sendable, (c)
 inheritance of MainActor isolation, (d) bounded TaskGroup patterns.

 Each drill names a specific GCD intuition and shows where Swift
 Concurrency breaks it.

 ----
 */
import Foundation

// MARK: - Drill 1: Where does Task { } actually run?

/*:
 ### Prompt 1
 GCD intuition: "spawn a closure on a background queue."
 Swift Concurrency: "Task { ... } *inherits actor isolation from its caller*."

 The interviewer pastes:
 ```swift
 @MainActor
 final class FeedVM {
     func reload() {
         Task {
             let data = downloadGigantic()  // CPU-heavy, not async
             self.posts = parse(data)
         }
     }
 }
 ```
 They ask: "Will this freeze the UI? Why?"

 Then: "Fix it without breaking actor isolation on `self.posts`."
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
 ### Prompt 2
 The actor below has a bug. Run the interviewer through (a) what's wrong,
 (b) how to fix without ditching the actor.

 **Hint**: actors serialize *single steps*, but they are REENTRANT —
 every `await` is a suspension point.
 */

actor BankAccount_Buggy {
    private var balance: Int = 100

    // External "validator" service we await
    func costlyAuditCheck(amount: Int) async -> Bool {
        try? await Task.sleep(for: .milliseconds(50))
        return balance >= amount
    }

    func withdraw(_ amount: Int) async -> Bool {
        guard await costlyAuditCheck(amount: amount) else { return false }
        // BUG: between the await above and the line below, another
        // withdraw() may have already run on this actor and changed `balance`.
        balance -= amount
        return true
    }
}

// TODO: Fix withdraw() so a second concurrent caller can't race the audit.

// MARK: - Drill 3: Bounded parallelism

/*:
 ### Prompt 3
 "Download these 50 URLs, max 5 in flight." Top-of-mind question.

 GCD instinct: DispatchSemaphore + DispatchQueue.concurrentPerform.
 Swift Concurrency: TaskGroup that primes N tasks, then enqueues one
 more whenever one finishes via `await group.next()`.
 */

func downloadAll(_ urls: [URL]) async throws -> [Data] {
    // TODO: bounded parallelism, max 5 concurrent.
    // Skeleton: withThrowingTaskGroup, prime 5, drain with `for try await`.
    return []
}

// MARK: - Drill 4: Sendable under Swift 6

/*:
 ### Prompt 4
 Compiler complains: "Capture of 'self' with non-Sendable type 'Cache'
 in a `@Sendable` closure." The class `Cache` is mutable. The interviewer
 wants to know your three options.
 */

final class Cache_Buggy {
    var entries: [URL: Data] = [:]
}

// TODO: 3 options to make Cache safely cross actor boundaries.

// MARK: - Drill 5: AsyncStream + cancellation

/*:
 ### Prompt 5
 Wrap a callback-based "tick every 500ms" timer as an `AsyncStream<Int>`
 such that:
 - the consumer can cancel it cleanly,
 - the producer stops emitting as soon as the consumer's Task is cancelled.

 Common bug: producer keeps firing forever after consumer dies.
 */

func makeTicker() -> AsyncStream<Int> {
    // TODO
    AsyncStream { continuation in
        // start a timer
        // continuation.yield(...)
        // continuation.onTermination = { ... stop the timer ... }
    }
}

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1: where Task runs -----
 // The buggy version: Task {} INSIDE a @MainActor class inherits MainActor.
 // So downloadGigantic() and parse() run on the MAIN THREAD → UI freezes.
 //
 // Fix: hop off main using Task.detached for heavy work, await result back.
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
     // Even cleaner: mark download/parse as `nonisolated` static funcs
     // so they don't capture the MainActor self at all.
 }

 // ----- Drill 2: actor reentrancy -----
 actor BankAccount {
     private var balance: Int = 100
     // Approach A: don't await mid-method. Snapshot first.
     func withdraw(_ amount: Int) async -> Bool {
         let snapshot = balance
         guard snapshot >= amount else { return false }
         // Note: even now there's a tiny window between snapshot and -=
         // that another reentrant call could exploit. But since we
         // didn't suspend, the actor's serial execution model protects us.
         balance -= amount
         return true
     }
     // Approach B: separate the async audit into a NONISOLATED helper
     // and re-enter the actor only for the mutation, rechecking invariants.
 }

 // ----- Drill 3: bounded TaskGroup -----
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

 // ----- Drill 4: Sendable -----
 // Three options when a mutable class refuses to cross an actor boundary:
 //
 // 1. Convert it to an `actor` — compiler-proven safe, recommended.
 //    actor Cache { private var entries: [URL: Data] = [:]; ... }
 //
 // 2. Make it deep-immutable: `final class` with all `let` properties of
 //    Sendable types → automatic Sendable conformance.
 //    final class Cache: Sendable { let entries: [URL: Data] }
 //
 // 3. Last resort: `@unchecked Sendable` + manual locking.
 //    final class Cache: @unchecked Sendable {
 //        private var _entries: [URL: Data] = [:]
 //        private let lock = NSLock()
 //        func get(_ url: URL) -> Data? { lock.lock(); defer { lock.unlock() }; return _entries[url] }
 //    }
 //
 // Senior framing: "Reach for the actor 95% of the time. @unchecked is a
 //  promise to the compiler that I've verified safety myself — used when
 //  bridging a battle-tested locked class from before Swift 6."

 // ----- Drill 5: AsyncStream cancellation -----
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
 // Usage:
 //   let consumer = Task {
 //       for await n in makeTicker() {
 //           print(n); if n > 4 { break }   // breaking the loop
 //       }                                  // cancels the stream task
 //   }
 // Or call consumer.cancel() externally → onTermination cancels producer.

*/
