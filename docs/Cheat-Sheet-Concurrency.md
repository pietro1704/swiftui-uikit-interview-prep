# ⚡️ Swift Concurrency Cheat Sheet

## async / await basics

```swift
func loadUser() async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

Task {
    do { let user = try await loadUser() }
    catch { print(error) }
}
```

## Parallelism

```swift
// async let — fixed N
async let a = fetchA()
async let b = fetchB()
let (resultA, resultB) = await (a, b)

// TaskGroup — dynamic N
let results = await withTaskGroup(of: Int.self) { group in
    for i in 1...10 { group.addTask { await compute(i) } }
    var out: [Int] = []
    for await r in group { out.append(r) }
    return out
}

// withThrowingTaskGroup → fail-fast (cancels siblings on first throw)
```

## Actor

```swift
actor Counter {
    private var value = 0
    func increment() { value += 1 }
    func get() -> Int { value }
}

let c = Counter()
await c.increment()
let v = await c.get()
```

## @MainActor

```swift
@MainActor
final class ViewModel: ObservableObject {
    @Published var state = ...   // guaranteed main-thread
}

// Spot usage:
Task { @MainActor in
    self.state = .loaded
}
```

## AsyncSequence / AsyncStream

```swift
let stream = AsyncStream<Int> { continuation in
    let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
        continuation.yield(Int.random(in: 1...100))
    }
    continuation.onTermination = { _ in timer.invalidate() }
}

for await value in stream { print(value) }
```

## Cancellation

```swift
let task = Task {
    for i in 1...100 {
        try Task.checkCancellation()       // throws CancellationError
        // or: if Task.isCancelled { return }
        try await Task.sleep(for: .seconds(1))  // cancels itself
    }
}

task.cancel()
```

## Continuation (legacy → async bridge)

```swift
func loadModern() async throws -> Data {
    try await withCheckedThrowingContinuation { cont in
        loadOldStyle { result in
            cont.resume(with: result)
        }
    }
}
```

## Sendable

```swift
struct User: Sendable {           // value types with Sendable members → auto
    let id: Int
    let name: String
}

final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var dict: [String: Data] = [:]
    // manual responsibility — lock all access
}
```

## Pitfalls

- ❌ `Task { @MainActor in ... }` inside something already on `@MainActor` → redundant
- ❌ Forgetting `await` → compile error (good — the compiler catches this)
- ⚠️ Actor reentrancy: state can change between `await` points
- ⚠️ Detached `Task {}` leaks if not cancelled. SwiftUI's `.task {}` cancels itself
