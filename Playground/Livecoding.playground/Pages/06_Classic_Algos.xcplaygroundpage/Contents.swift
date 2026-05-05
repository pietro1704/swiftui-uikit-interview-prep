// Page 06 — Classic livecoding problems in Swift
// Read prompts/explanations: ../../../../docs/livecoding/06-classic-algos.md

import Foundation

// MARK: Drill 1 — Debounce a function

actor Debouncer {
    let delay: Duration
    private var task: Task<Void, Never>?
    init(delay: Duration) { self.delay = delay }
    func call(_ action: @escaping @Sendable () async -> Void) {
        // TODO: cancel existing task; schedule a new one that sleeps `delay`
        // and runs `action` only if not cancelled.
    }
}

// MARK: Drill 2 — LRU Cache

final class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    init(capacity: Int) { self.capacity = capacity }
    // TODO: doubly-linked node, head/tail, dict [Key: Node]
    func get(_ key: Key) -> Value? { nil }
    func set(_ key: Key, _ value: Value) {}
}

// MARK: Drill 3 — Async semaphore

actor AsyncSemaphore {
    private var permits: Int
    init(permits: Int) { self.permits = permits }
    // TODO: storage of suspended continuations
    // TODO: func wait() async
    // TODO: func signal()
}

// MARK: Drill 4 — Throttle (leading edge)

actor Throttler {
    let interval: Duration
    private var lastFiredAt: ContinuousClock.Instant?
    init(interval: Duration) { self.interval = interval }
    func call(_ action: () async -> Void) async {
        // TODO: if (now - lastFiredAt) >= interval, fire and update lastFiredAt.
        //       else, drop the call.
    }
}

// MARK: Drill 5 — Custom AsyncSequence

struct CountdownSequence: AsyncSequence {
    typealias Element = Int
    let from: Int
    let delay: Duration
    // TODO: replace stub with proper AsyncIterator that yields N…0 with `delay`.
    struct AsyncIterator: AsyncIteratorProtocol {
        mutating func next() async -> Int? { nil }
    }
    func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
}

// MARK: Drill 6 — Composite + Factory

protocol AnalyticsService {
    func track(_ event: String, properties: [String: String])
}
// TODO: struct FirebaseAnalytics: AnalyticsService { ... }
// TODO: struct MixpanelAnalytics: AnalyticsService { ... }
// TODO: struct CompositeAnalytics: AnalyticsService { ... fans out ... }
// TODO: factory function that picks composition based on a Bool flag.

// MARK: Drill 7 — Deep link parser

enum Route_07: Hashable {
    case profile(String)
    case post(UUID)
}
// TODO: struct DeepLinkParser { func route(from url: URL) -> Route_07? }
// TODO: a tiny round-trip test.

/*

================================================================================
SOLUTIONS
================================================================================

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

// ----- Drill 2: LRU -----
final class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var map: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?

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
        if permits > 0 { permits -= 1; return }
        await withCheckedContinuation { c in waiters.append(c) }
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

// ----- Drill 4: Throttle leading edge -----
actor Throttler {
    let interval: Duration
    private var lastFiredAt: ContinuousClock.Instant?
    init(interval: Duration) { self.interval = interval }
    func call(_ action: () async -> Void) async {
        let now = ContinuousClock.now
        if let last = lastFiredAt, now - last < interval { return }
        lastFiredAt = now
        await action()
    }
}

// ----- Drill 5: AsyncSequence -----
struct CountdownSequence: AsyncSequence, Sendable {
    typealias Element = Int
    let from: Int
    let delay: Duration
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(current: from, delay: delay)
    }
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

// ----- Drill 6: Composite + Factory -----
struct FirebaseAnalytics: AnalyticsService {
    func track(_ event: String, properties: [String: String]) { /* send to Firebase */ }
}
struct MixpanelAnalytics: AnalyticsService {
    func track(_ event: String, properties: [String: String]) { /* send to Mixpanel */ }
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
// Round-trip:
//   let p = DeepLinkParser()
//   assert(p.route(from: URL(string: "myapp://profile/abc123")!) == .profile("abc123"))
//   let id = UUID()
//   assert(p.route(from: URL(string: "myapp://post/\(id)")!) == .post(id))
//   assert(p.route(from: URL(string: "https://google.com")!) == nil)

*/
