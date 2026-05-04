/*:
 # 06 — Classic livecoding problems in Swift

 Five problems senior iOS screens love. Each is small enough
 to whiteboard in 15-25 min while you talk through trade-offs.

 ----
 */
import Foundation

// MARK: - Drill 1: Debounce a function

/*:
 ### Prompt 1
 Build a debouncer: given a delay, return a function that, when called
 repeatedly, only fires the action `delay` after the LAST call.

 Constraints:
 - thread-safe (think: typing in a search box, multiple keystrokes from main).
 - cancellable.
 - Use Swift Concurrency, not GCD.
 */

actor Debouncer {
    let delay: Duration
    private var task: Task<Void, Never>?

    init(delay: Duration) { self.delay = delay }

    func call(_ action: @escaping @Sendable () async -> Void) {
        // TODO: cancel existing task; schedule a new one that sleeps `delay`
        // and runs `action` only if not cancelled.
    }
}

// MARK: - Drill 2: LRU Cache

/*:
 ### Prompt 2
 Build an `LRUCache<Key: Hashable, Value>` with O(1) get + O(1) set,
 evicting the least-recently-used entry when capacity is reached.

 Mental model: hashmap + doubly-linked list. The hashmap maps key→node;
 the list maintains order; "recent" goes to head.

 Don't reach for stdlib OrderedDictionary — write the doubly-linked list yourself.
 */

final class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    init(capacity: Int) { self.capacity = capacity }

    // TODO: doubly-linked node, head/tail, dict [Key: Node]

    func get(_ key: Key) -> Value? {
        // TODO
        nil
    }
    func set(_ key: Key, _ value: Value) {
        // TODO
    }
}

// MARK: - Drill 3: Async semaphore

/*:
 ### Prompt 3
 GCD has DispatchSemaphore. Swift Concurrency does NOT — `wait()` would
 block, defeating cooperative scheduling.

 Build an `AsyncSemaphore` with `wait()` and `signal()` that:
 - allows up to N concurrent acquirers (bounded permits),
 - suspends excess acquirers (no busy-wait),
 - resumes them in FIFO order on signal.
 */

actor AsyncSemaphore {
    private var permits: Int
    init(permits: Int) { self.permits = permits }

    // TODO: storage of suspended continuations
    // TODO: func wait() async
    // TODO: func signal()
}

// MARK: - Drill 4: Throttle (leading edge)

/*:
 ### Prompt 4
 Different from debounce: throttle FIRES IMMEDIATELY on the first call
 in a window, then ignores further calls until `interval` elapses.
 (Think: don't let the user spam-tap "Send".)
 */

actor Throttler {
    let interval: Duration
    private var lastFiredAt: ContinuousClock.Instant?
    init(interval: Duration) { self.interval = interval }

    func call(_ action: () async -> Void) async {
        // TODO: if (now - lastFiredAt) >= interval, fire and update lastFiredAt.
        //       else, drop the call.
    }
}

// MARK: - Drill 5: Custom AsyncSequence

/*:
 ### Prompt 5
 Build a `CountdownSequence: AsyncSequence` that yields Int from N down
 to 0 with a configurable delay between elements. Make it Sendable-clean.
 */

struct CountdownSequence: AsyncSequence {
    typealias Element = Int
    let from: Int
    let delay: Duration

    // TODO: replace this stub with a proper AsyncIterator that yields N…0 with `delay`.
    struct AsyncIterator: AsyncIteratorProtocol {
        mutating func next() async -> Int? { nil }   // ← your code goes here
    }
    func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
}

// MARK: - Drill 6: Composite + Factory

/*:
 ### Prompt 6 — from-scratch
 Build an `AnalyticsService` protocol with two concrete implementations
 (Firebase, Mixpanel) plus a `CompositeAnalytics` that fans out to all
 of them. Show how you'd build the right composition at startup based
 on a feature flag.
 */

protocol AnalyticsService {
    func track(_ event: String, properties: [String: String])
}

// TODO: struct FirebaseAnalytics: AnalyticsService { ... }
// TODO: struct MixpanelAnalytics: AnalyticsService { ... }
// TODO: struct CompositeAnalytics: AnalyticsService { ... fans out ... }
// TODO: factory function that picks composition based on a Bool flag.

// MARK: - Drill 7: Deep link parser

/*:
 ### Prompt 7 — from-scratch
 Build a `DeepLinkParser` that turns these URLs into typed `Route` values:
   - `myapp://profile/abc123`         → .profile(\"abc123\")
   - `myapp://post/<UUID>`             → .post(uuid)
   - anything else                     → nil

 Show a unit test that round-trips one of each.
 */

enum Route_07: Hashable {
    case profile(String)
    case post(UUID)
}

// TODO: struct DeepLinkParser { func route(from url: URL) -> Route_07? }
// TODO: a tiny round-trip test (XCTAssertEqual on parsed result).

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1: Debouncer -----
 actor Debouncer {
     let delay: Duration
     private var task: Task<Void, Never>?
     init(delay: Duration) { self.delay = delay }

     func call(_ action: @escaping @Sendable () async -> Void) {
         task?.cancel()
         task = Task { [delay] in
             try? await Task.sleep(for: delay)
             guard !Task.isCancelled else { return }
             await action()
         }
     }
 }
 // Talk-track: "Each call cancels the prior pending task and replaces it.
 //  When typing settles for `delay`, the task wakes up, sees it wasn't
 //  cancelled, runs the action. Actor serializes call() so the task
 //  swap is race-free."

 // ----- Drill 2: LRU -----
 final class LRUCache<Key: Hashable, Value> {
     private let capacity: Int
     private var map: [Key: Node] = [:]
     private var head: Node?    // most recent
     private var tail: Node?    // least recent

     final class Node {
         let key: Key
         var value: Value
         var prev: Node?
         var next: Node?
         init(_ key: Key, _ value: Value) { self.key = key; self.value = value }
     }

     init(capacity: Int) { self.capacity = capacity }

     func get(_ key: Key) -> Value? {
         guard let node = map[key] else { return nil }
         moveToHead(node)
         return node.value
     }

     func set(_ key: Key, _ value: Value) {
         if let node = map[key] {
             node.value = value
             moveToHead(node)
             return
         }
         let node = Node(key, value)
         map[key] = node
         insertAtHead(node)
         if map.count > capacity, let stale = tail {
             remove(stale); map.removeValue(forKey: stale.key)
         }
     }

     private func insertAtHead(_ n: Node) {
         n.next = head; head?.prev = n; head = n
         if tail == nil { tail = n }
     }
     private func remove(_ n: Node) {
         n.prev?.next = n.next; n.next?.prev = n.prev
         if head === n { head = n.next }
         if tail === n { tail = n.prev }
         n.prev = nil; n.next = nil
     }
     private func moveToHead(_ n: Node) { remove(n); insertAtHead(n) }
 }

 // ----- Drill 3: AsyncSemaphore -----
 actor AsyncSemaphore {
     private var permits: Int
     private var waiters: [CheckedContinuation<Void, Never>] = []
     init(permits: Int) { self.permits = permits }

     func wait() async {
         if permits > 0 {
             permits -= 1
             return
         }
         await withCheckedContinuation { c in
             waiters.append(c)
         }
     }

     func signal() {
         if let c = waiters.first {
             waiters.removeFirst()
             c.resume()
         } else {
             permits += 1
         }
     }
 }
 // Trade-off note: by holding waiters in an array we pay O(n) on cancel
 //  if you ever need cancellation; for that, use withCheckedContinuation
 //  and a lookup token. Senior framing welcome.

 // ----- Drill 4: Throttle leading edge -----
 actor Throttler {
     let interval: Duration
     private var lastFiredAt: ContinuousClock.Instant?
     init(interval: Duration) { self.interval = interval }

     func call(_ action: () async -> Void) async {
         let now = ContinuousClock.now
         if let last = lastFiredAt, now - last < interval {
             return
         }
         lastFiredAt = now
         await action()
     }
 }

 // ----- Drill 5: AsyncSequence -----
 struct CountdownSequence: AsyncSequence, Sendable {
     typealias Element = Int
     let from: Int
     let delay: Duration

     func makeAsyncIterator() -> AsyncIterator { AsyncIterator(current: from, delay: delay) }

     struct AsyncIterator: AsyncIteratorProtocol {
         var current: Int
         let delay: Duration
         mutating func next() async -> Int? {
             guard current >= 0 else { return nil }
             try? await Task.sleep(for: delay)
             defer { current -= 1 }
             return current
         }
     }
 }
 // Use:
 //   for await n in CountdownSequence(from: 3, delay: .seconds(1)) { print(n) }

 // ----- Drill 6: Composite + Factory -----
 struct FirebaseAnalytics: AnalyticsService {
     func track(_ event: String, properties: [String: String]) {
         // send to Firebase
     }
 }
 struct MixpanelAnalytics: AnalyticsService {
     func track(_ event: String, properties: [String: String]) {
         // send to Mixpanel
     }
 }
 struct CompositeAnalytics: AnalyticsService {
     let services: [any AnalyticsService]
     func track(_ event: String, properties: [String: String]) {
         services.forEach { $0.track(event, properties: properties) }
     }
 }
 enum AnalyticsFactory {
     static func make(useDualPipeline: Bool) -> any AnalyticsService {
         useDualPipeline
             ? CompositeAnalytics(services: [FirebaseAnalytics(), MixpanelAnalytics()])
             : FirebaseAnalytics()
     }
 }
 // Senior framing: protocol + composite is how you get a "fan-out" without
 //  the rest of the app knowing — every consumer sees `any AnalyticsService`.

 // ----- Drill 7: DeepLinkParser -----
 struct DeepLinkParser {
     func route(from url: URL) -> Route_07? {
         guard url.scheme == "myapp" else { return nil }
         switch url.host {
         case "profile":
             let id = url.lastPathComponent
             guard !id.isEmpty, id != "/" else { return nil }
             return .profile(id)
         case "post":
             guard let uuid = UUID(uuidString: url.lastPathComponent) else { return nil }
             return .post(uuid)
         default: return nil
         }
     }
 }
 // Tiny round-trip:
 //   let p = DeepLinkParser()
 //   assert(p.route(from: URL(string: "myapp://profile/abc123")!) == .profile("abc123"))
 //   let id = UUID()
 //   assert(p.route(from: URL(string: "myapp://post/\(id)")!) == .post(id))
 //   assert(p.route(from: URL(string: "https://google.com")!) == nil)

*/
