/*:
 # 05 — ARC, retain cycles, and copy-on-write

 Memory questions are senior gates. Six years of UIKit experience helps
 here, but interviewers love the *Combine + closure* combos that didn't
 exist in early Swift.

 ----
 */
import Foundation
import Combine

// MARK: - Drill 1: Spot the cycle

/*:
 ### Prompt 1
 The interviewer pastes this and asks if it leaks. If yes, fix it without
 changing the public API.
 */

final class Search_Buggy {
    @Published var query = ""
    private var bag = Set<AnyCancellable>()
    var results: [String] = []

    func bind() {
        $query
            .map { $0.uppercased() }
            .sink { value in
                self.results = [value]   // 🔍
            }
            .store(in: &bag)
    }
}

// TODO: identify the cycle, then write a fixed bind().

// MARK: - Drill 2: weak vs unowned

/*:
 ### Prompt 2
 You replace `self.results = [value]` with `[weak self] in self?.results = [value]`.
 The interviewer asks: "Why didn't you use `[unowned self]`? It's faster."

 Write the answer — when is each correct?
 */

// (verbal — bullet points at bottom)

// MARK: - Drill 3: Copy-on-Write — does this copy?

/*:
 ### Prompt 3
 ```swift
 var a = Array(repeating: 1, count: 1_000_000)
 var b = a       // ① copies?
 b.append(2)     // ② copies?
 print(a.count)  // ③ outputs?
 ```
 Walk through what happens at each step.
 */

// (verbal answer)

// MARK: - Drill 4: Build CoW from scratch

/*:
 ### Prompt 4
 Implement a value type `Buffer` that holds a class-backed `Storage` and
 only clones the storage when mutated AND the storage is shared. The
 magic key word: `isKnownUniquelyReferenced`.
 */

final class Storage {
    var data: [Int]
    init(_ data: [Int]) { self.data = data }
    func clone() -> Storage { Storage(data) }
}

struct Buffer {
    private var storage: Storage = Storage([])

    var data: [Int] { storage.data }

    // TODO: mutating func append(_ x: Int)
    //   - check isKnownUniquelyReferenced(&storage)
    //   - clone if shared
    //   - mutate
}

// MARK: - Drill 5: Closure capturing in Swift Concurrency

/*:
 ### Prompt 5
 ```swift
 final class FeedVM {
     var posts: [String] = []
     func load() {
         Task {
             let new = try? await fetch()
             self.posts = new ?? []
         }
     }
 }
 ```
 The interviewer asks: "Same retain-cycle worry as the Combine sink?"

 Hint: NO — explain why Task { } is different from a stored closure.
 */

// (verbal answer)

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1: cycle -----
 // Cycle: self → bag → AnyCancellable → closure → self.
 // The closure captures `self` strongly; AnyCancellable is owned by self;
 // the publisher chain holds the closure. None drops → leak.
 //
 // Fix:
 final class Search {
     @Published var query = ""
     private var bag = Set<AnyCancellable>()
     var results: [String] = []
     func bind() {
         $query
             .map { $0.uppercased() }
             .sink { [weak self] value in
                 self?.results = [value]
             }
             .store(in: &bag)
     }
 }
 // Even nicer: $query.map { ... }.assign(to: &$results) — Combine's
 // built-in cycle-safe assignment when results is also @Published.

 // ----- Drill 2: weak vs unowned -----
 //
 // [weak self]:
 //   - self becomes Optional, deallocates safely → safe.
 //   - tiny perf cost (extra ref-count load to check liveness).
 //   - USE THIS by default for closures that may outlive self.
 //
 // [unowned self]:
 //   - non-optional, no liveness check.
 //   - CRASH if self deallocates before the closure fires.
 //   - USE ONLY when self's lifetime is provably ≥ closure's:
 //     e.g., closures stored on `self` itself that fire only while
 //     self is alive (e.g., a custom button's tap handler defined inline).
 //
 // For Combine sinks, network completion handlers, AsyncStream consumers:
 // ALWAYS [weak self]. Publisher may emit after view dismiss.

 // ----- Drill 3: CoW walkthrough -----
 // ① `var b = a` → O(1). Both a and b point to the SAME backing buffer.
 //    Reference count of the buffer = 2.
 // ② `b.append(2)` → Array calls `_makeUniqueAndReserveCapacityIfNotUnique`
 //    internally. Sees buffer is shared (refcount > 1) → CLONES THE BUFFER,
 //    `b` now owns a private copy, then mutates. `a` stays untouched.
 // ③ Prints 1_000_000. `a` was not modified.
 //
 // CoW classes: Array, Dictionary, Set, String. Custom value types can
 //  opt in via `isKnownUniquelyReferenced`.

 // ----- Drill 4: hand-rolled CoW -----
 struct Buffer {
     private var storage: Storage = Storage([])
     var data: [Int] { storage.data }

     mutating func append(_ x: Int) {
         if !isKnownUniquelyReferenced(&storage) {
             storage = storage.clone()      // share→clone exactly when needed
         }
         storage.data.append(x)
     }
 }
 // `Buffer` now has value semantics: `var b = a` is O(1), `b.append(...)`
 // doesn't touch `a`'s storage. Same deal as stdlib Array.

 // ----- Drill 5: Task vs stored closure -----
 // No cycle.
 // Reason: `Task { ... }` is unstructured but the Task does NOT live on
 // self. Once the closure body completes, the Task and its captured
 // `self` are released. Compare to:
 //   var bag = Set<AnyCancellable>(); $query.sink { self.x = $0 }.store(in: &bag)
 // The cancellable is *kept alive* by self → cycle.
 //
 // If you want to be belt-and-suspenders, use `[weak self] in` inside
 // Task — but it's not the same liability.
 //
 // The ACTUAL cycle worry with Task: storing the Task handle on self
 //   `self.handle = Task { ... }` → if the task body captures self,
 //   you have a transient cycle until the task finishes.

*/
