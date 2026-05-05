// Page 05 — ARC, retain cycles, and copy-on-write
// Read prompts/explanations: ../../../../docs/livecoding/05-arc-memory.md

import Foundation
import Combine

// MARK: Drill 1 — Spot the cycle (bug-hunt)

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

// MARK: Drill 2 — weak vs unowned (discussion)

// MARK: Drill 3 — Copy-on-Write — does this copy? (discussion)

// MARK: Drill 4 — Build CoW from scratch

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

// MARK: Drill 5 — Closure capturing in Swift Concurrency (discussion)

// MARK: Drill 6 — Property wrapper composition

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
// TODO: discuss what happens if you stack @SomeOther @Clamped.

// MARK: Drill 7 — AnyHashable performance (discussion)

/*

================================================================================
SOLUTIONS
================================================================================

// ----- Drill 1: cycle -----
// Cycle: self → bag → AnyCancellable → closure → self.
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
// [weak self]: optional, deallocates safely → safe; tiny perf cost.
//              USE BY DEFAULT for closures that may outlive self.
// [unowned self]: non-optional, no liveness check; CRASH if self deallocates.
//                 USE ONLY when self's lifetime is provably ≥ closure's.

// ----- Drill 3: CoW walkthrough -----
// ① var b = a → O(1). Both point to SAME backing buffer; refcount=2.
// ② b.append(2) → Array calls _makeUniqueAndReserveCapacityIfNotUnique;
//    sees buffer shared → CLONES; b owns private copy, mutates. a unchanged.
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

// ----- Drill 5: Task vs stored closure -----
// No cycle. The Task does NOT live on self — once the body completes,
// the Task and its captured `self` are released.
// Compare: Set<AnyCancellable> stored on self → cycle.
// Task cycle worry: storing the Task handle on self
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
// - $x is whatever Published projects (Publisher<Clamped<Int>, Never>)

// ----- Drill 7: AnyHashable performance -----
// Boxes the underlying type at runtime → extra indirection per lookup.
// 2-5x slower than typed Dictionary<Int, Foo> in hot paths.
// RIGHT for: heterogeneous keying (analytics events with mixed key types),
//            bridging from NS APIs.
// WRONG for: any internal data structure where keys are known.

*/
