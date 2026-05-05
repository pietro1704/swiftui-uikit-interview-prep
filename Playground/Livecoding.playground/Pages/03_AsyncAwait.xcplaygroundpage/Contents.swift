// Page 03 — async/await + Structured Concurrency
// Read prompts/explanations: ../../../../docs/livecoding/03-async-await.md

import Foundation

// MARK: Drill 1 — Where does Task { } actually run? (bug-hunt)

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

// MARK: Drill 2 — Actor reentrancy bug

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

// MARK: Drill 3 — Bounded parallelism

func downloadAll(_ urls: [URL]) async throws -> [Data] {
    // TODO: bounded parallelism, max 5 concurrent.
    return []
}

// MARK: Drill 4 — Sendable under Swift 6 (bug-hunt)

final class Cache_Buggy {
    var entries: [URL: Data] = [:]
}
// TODO: 3 options to make Cache safely cross actor boundaries.

// MARK: Drill 5 — AsyncStream + cancellation

func makeTicker() -> AsyncStream<Int> {
    // TODO
    AsyncStream { continuation in
        // start a timer
        // continuation.yield(...)
        // continuation.onTermination = { ... stop the timer ... }
    }
}

// MARK: Drill 6 — GlobalActor

// TODO:
// 1. @globalActor actor DatabaseActor { static let shared = DatabaseActor() }
// 2. annotate a free function and a struct with @DatabaseActor

// MARK: Drill 7 — isolated parameters

actor Counter {
    var value = 0
}
// TODO: func bump(_ counter: isolated Counter) { ... }

// MARK: Drill 8 — Task priority inheritance (bug-hunt)

@MainActor
func startHeavyWork() {
    Task(priority: .background) {
        await heavyWork()   // actually runs at .userInitiated. Why?
    }
}
func heavyWork() async {}
// TODO: rewrite to genuinely run at .background.

// MARK: Drill 9 — AsyncSequence vs Combine

// TODO: write Combine and AsyncSequence solutions for "tick every second, take 5".

// MARK: Drill 10 — Cancellation propagation (bug-hunt)

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

// MARK: Drill 11 — async let lifetime (bug-hunt)

func loadHomeScreen() async {
    async let banner = fetchBanner()    // never used!
    async let posts = fetchPosts()
    let p = await posts
    render(p)
}   // ← here, banner is auto-awaited; you pay for the call.

func fetchBanner() async -> String { "" }
func fetchPosts() async -> [String] { [] }
func render(_ posts: [String]) {}
// TODO: discuss the issue + fix it.

// MARK: Drill 12 — MainActor in init

@MainActor
final class FeedVM_12 {
    var posts: [String] = []
    let id: UUID
    init(id: UUID) {                   // forces caller onto MainActor
        self.id = id
    }
}
// TODO: rewrite init so it can be called from any context.

// MARK: - Live preview
// Run the playground, then Editor → Live View (⌥⌘↵).
// This page is mostly async/CLI work — the live view is a console showing
// output from a quick demo (here: a 3-tick countdown).

import SwiftUI
import PlaygroundSupport

@MainActor
final class ConsoleLog: ObservableObject {
    @Published var lines: [String] = []
    func log(_ s: String) { lines.append(s) }
}

struct Page3LiveView: View {
    @ObservedObject var log: ConsoleLog
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(log.lines.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.system(size: 13, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(width: 360, height: 240)
        .background(.black.opacity(0.05))
    }
}

let demoLog = ConsoleLog()

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.setLiveView(Page3LiveView(log: demoLog))

Task { @MainActor in
    demoLog.log("▶ async demo: counting 3 → 0 every 0.5s")
    for i in stride(from: 3, through: 0, by: -1) {
        demoLog.log("  tick \(i)")
        try? await Task.sleep(for: .milliseconds(500))
    }
    demoLog.log("✓ done. Edit this Task to demo any other drill.")
}

/*

================================================================================
SOLUTIONS
================================================================================

// ----- Drill 1 -----
@MainActor
final class FeedVM {
    var posts: [String] = []
    func reload() {
        Task {
            let posts: [String] = await Task.detached(priority: .userInitiated) {
                let data = self.downloadGigantic()
                return self.parse(data)
            }.value
            self.posts = posts
        }
    }
}

// ----- Drill 2 -----
actor BankAccount {
    private var balance: Int = 100
    func withdraw(_ amount: Int) async -> Bool {
        let snapshot = balance
        guard snapshot >= amount else { return false }
        balance -= amount
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
// 3) @unchecked Sendable + manual NSLock — last resort.

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
@DatabaseActor func runMigration() async {}
@DatabaseActor struct UserStore {
    func save(_ user: User) {}
    func load(id: UUID) -> User? { nil }
}

// ----- Drill 7 -----
func bump(_ counter: isolated Counter) {
    counter.value += 1
}

// ----- Drill 8 -----
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
// Async (custom AsyncStream)
//   for await n in tickerStream.prefix(5) { print(n) }

// ----- Drill 10 -----
func computeAll(_ items: [Int]) async throws {
    for item in items {
        try Task.checkCancellation()
        let result = expensiveCompute(item)
        print(result)
    }
}

// ----- Drill 11 -----
// async let creates an implicit child task. Scope-end auto-awaits it.
// fetchBanner() does run; scope blocks until it completes.
//
// Fix A: drop async let, use unstructured Task if optional.
// Fix B: actually use the value.

// ----- Drill 12 -----
@MainActor
final class FeedVM_12_Fixed {
    var posts: [String] = []
    let id: UUID
    nonisolated init(id: UUID) {
        self.id = id
    }
}

*/
