/*:
 # 05 — ARC, retain cycles, and copy-on-write

 Memory questions are senior gates. Six years of UIKit experience helps,
 but interviewers love the *Combine + closure* combos that didn't exist
 in early Swift, plus property wrapper composition and AnyHashable.

 ----
 */
import Foundation
import Combine

// MARK: - Drill 1: Spot the cycle

/*:
 ### Prompt 1 — bug-hunt
 Does this leak? If yes, fix it without changing the public API.
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
 ### Prompt 2 — discussion
 You replace `self.results = ...` with `[weak self]` + `self?.results = ...`.
 The interviewer asks: "Why didn't you use `[unowned self]`? It's faster."

 When is each correct?
 */

// (verbal — bullet points at bottom)

// MARK: - Drill 3: Copy-on-Write — does this copy?

/*:
 ### Prompt 3 — discussion
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
 ### Prompt 4 — from-scratch
 Implement a value type `Buffer` that holds a class-backed `Storage` and
 only clones storage when mutated AND the storage is shared. Magic word:
 `isKnownUniquelyReferenced`.
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
 ### Prompt 5 — discussion
 ```
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
 Same retain-cycle worry as the Combine sink? Hint: NO — explain why
 `Task { }` is different from a stored closure.
 */

// (verbal answer)

// MARK: - Drill 6: Property wrapper composition

/*:
 ### Prompt 6 — bug-hunt → from-scratch
 You write `@Published @SomeWrapper var x: Int = 0` in a class. Order
 of the wrappers matters — explain how nesting works, and write a tiny
 `@Clamped` wrapper that composes correctly with another wrapper.
 */

@propertyWrapper
struct Clamped_06<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>
    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
}

// TODO: write a struct Player with @Clamped on a stored property.
// TODO: discuss what happens if you stack @SomeOther @Clamped — what
// projectedValue gets exposed via $x?

// MARK: - Drill 7: AnyHashable performance

/*:
 ### Prompt 7 — discussion
 When does `[AnyHashable: Any]` bite you? When is it the right tool?
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
 // Even nicer: $query.map { ... }.assign(to: &$results) — built-in cycle-safe.

 // ----- Drill 2: weak vs unowned -----
 //
 // [weak self]:
 //   - self becomes Optional, deallocates safely → safe.
 //   - tiny perf cost (extra ref-count load to check liveness).
 //   - USE BY DEFAULT for closures that may outlive self.
 //
 // [unowned self]:
 //   - non-optional, no liveness check.
 //   - CRASH if self deallocates before the closure fires.
 //   - USE ONLY when self's lifetime is provably ≥ closure's.

 // ----- Drill 3: CoW walkthrough -----
 // ① `var b = a` → O(1). Both point to SAME backing buffer; refcount=2.
 // ② `b.append(2)` → Array calls _makeUniqueAndReserveCapacityIfNotUnique;
 //    sees buffer shared → CLONES, b owns private copy, mutates. a unchanged.
 // ③ Prints 1_000_000.

 // ----- Drill 4: hand-rolled CoW -----
 struct Buffer_Sol {
     private var storage: Storage = Storage([])
     var data: [Int] { storage.data }
     mutating func append(_ x: Int) {
         if !isKnownUniquelyReferenced(&storage) {
             storage = storage.clone()
         }
         storage.data.append(x)
     }
 }
 // Buffer now has value semantics: var b = a is O(1); b.append() doesn't
 // touch a's storage.

 // ----- Drill 5: Task vs stored closure -----
 // No cycle. The Task does NOT live on self — once the body completes,
 // the Task and its captured `self` are released. Compare to:
 //   var bag = Set<AnyCancellable>(); $query.sink { self.x = $0 }.store(in: &bag)
 // The cancellable IS kept alive by self → cycle.
 //
 // The cycle worry with Task: storing the Task handle on self
 //   self.handle = Task { ... }
 // creates a transient cycle until the body finishes.

 // ----- Drill 6: Property wrapper composition -----
 struct Player {
     @Clamped_06(0...100) var hp: Int = 50
 }

 // Stacking: `@Wrapper2 @Clamped var x` desugars to `Wrapper2<Clamped<Int>>`.
 // The OUTER wrapper provides $x. So in:
 //   @Published @Clamped(0...100) var hp: Int = 50
 // - storage type: Published<Clamped<Int>>
 // - x's getter goes Published.value.wrappedValue
 // - $x is whatever Published projects (Publisher<Clamped<Int>, Never>)
 //
 // Practical advice: composition is rare. Most teams pick one wrapper at
 // a time. If you compose, write a 3-line comment explaining the order.

 // ----- Drill 7: AnyHashable performance -----
 //
 // AnyHashable boxes the underlying type at runtime. Hashing costs an
 // extra pointer indirection per lookup; equality goes through dynamic
 // dispatch. For hot paths (large dicts, frequent lookups), it can be
 // 2-5x slower than typed Dictionary<Int, Foo>. Plus you lose compile-
 // time type safety on values.
 //
 // RIGHT for: Notification.userInfo (legacy API), genuinely heterogeneous
 //  keying (analytics events with mixed key types), bridging from NS APIs.
 //
 // WRONG for: any internal data structure where keys are known. Type the
 //  dict.
 //
 // Senior framing: "AnyHashable is an existential — pay only when you need it."

*/
