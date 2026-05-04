/*:
 # 04 — Generics, PAT, opaque vs existential

 Senior trap: confusing `some Protocol` (opaque, single concrete type
 hidden from caller) with `any Protocol` (existential box, type erased
 at runtime). Plus: associated types defeat plain `[any DataSource]`.

 ----
 */
import Foundation

// MARK: - Drill 1: some vs any

/*:
 ### Prompt 1
 The interviewer shows two functions:
 ```swift
 func a() -> Animal { ... }       // pre-Swift 5.7, defaults to existential
 func b() -> some Animal { ... }
 func c() -> any Animal { ... }
 ```
 They ask: "Walk me through the runtime cost and call-site implications
 of each."

 No code to write — talk through it. Then write the table at the bottom.
 */

// (no code; verbal answer)

// MARK: - Drill 2: Why doesn't this compile?

/*:
 ### Prompt 2
 The compiler rejects this. Why, and what's the minimum fix?
 */

protocol DataSource_Bad {
    associatedtype Item
    func load() async throws -> [Item]
}

// func makeSources() -> [DataSource_Bad] {  // ❌ won't compile
//     [LocalUsers(), RemoteFlags()]
// }

struct LocalUsers: DataSource_Bad {
    func load() async throws -> [String] { ["Ana", "Beto"] }
}
struct RemoteFlags: DataSource_Bad {
    func load() async throws -> [Bool] { [true, false] }
}

// TODO: write a function returning a heterogeneous collection of DataSources.

// MARK: - Drill 3: Type eraser by hand

/*:
 ### Prompt 3
 The standard library has `AnySequence`, `AnyPublisher`. Build `AnyDataSource`
 — a manual type eraser that hides the concrete type but preserves Item.
 */

protocol DataSource {
    associatedtype Item
    func load() async throws -> [Item]
}

// TODO: struct AnyDataSource<Item> { ... }

// MARK: - Drill 4: Primary associated types (iOS 17+)

/*:
 ### Prompt 4
 Swift 5.7 lets you constrain the existential's associated type at the
 call site. Show the new syntax for:
 - "any Sequence whose Element is Int"
 - "some Collection where Element is String"
 */

// TODO: function signature using `some Collection<String>`
// TODO: function signature using `any Sequence<Int>`

// MARK: - Drill 5: Generic + protocol conformance vs existential

/*:
 ### Prompt 5
 The interviewer asks: "Why doesn't this work?"
 ```swift
 func first<T: Equatable>(in array: [any Equatable]) -> T? { ... }
 ```
 They want to hear: existentials erase per-element type → element 0 may
 be Int and element 1 String → they aren't comparable to each other.

 Write the CORRECT signature for a `firstDuplicate(_:)` function over
 a homogeneous Hashable array.
 */

// TODO: func firstDuplicate<T: Hashable>(_ items: [T]) -> T?

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1: some vs any cheat-sheet -----
 //
 // | Form          | Concrete type known at compile time?    | Runtime box? | Heterogeneous collection? | Static dispatch? |
 // | ------------- | --------------------------------------- | ------------ | ------------------------- | ---------------- |
 // | `some P`      | YES — caller doesn't see it but compiler does | no           | NO (single hidden type)   | YES              |
 // | `any P`       | NO — type carried in existential at runtime | yes          | YES                       | NO (witness table) |
 // | bare `P` <5.7 | implicit `any P`                        | yes          | yes                       | no               |
 //
 // Rule of thumb: reach for `some` when you can; `any` only when
 // heterogeneity is the *requirement*.

 // ----- Drill 2: heterogeneous PATs -----
 // Won't compile because `[DataSource_Bad]` would need a single
 // associated type, but LocalUsers.Item != RemoteFlags.Item.
 //
 // Fix A (Swift 5.7+): primary associated types — but only works if
 //   all sources share the same Item.
 //   protocol DataSource<Item> { associatedtype Item; ... }
 //   func makeSources() -> [any DataSource<String>]   // homogeneous Item
 //
 // Fix B: type-erase to a non-PAT wrapper. See AnyDataSource below.

 // ----- Drill 3: AnyDataSource type eraser -----
 struct AnyDataSource<Item> {
     private let _load: () async throws -> [Item]
     init<S: DataSource>(_ source: S) where S.Item == Item {
         self._load = source.load
     }
     func load() async throws -> [Item] { try await _load() }
 }
 // Now [AnyDataSource<String>] is fine. Same recipe Combine uses.

 // ----- Drill 4: primary associated types -----
 func process(items: any Sequence<Int>) -> Int { items.reduce(0, +) }
 func toUpper(items: some Collection<String>) -> [String] {
     items.map { $0.uppercased() }
 }
 // Senior note: `some Collection<String>` reads like a constrained generic
 //  but lives in the function signature — no need to declare T. Cleaner
 //  call-sites, same static-dispatch perks as `<T: Collection where T.Element == String>`.

 // ----- Drill 5: firstDuplicate -----
 func firstDuplicate<T: Hashable>(_ items: [T]) -> T? {
     var seen = Set<T>()
     for item in items {
         if !seen.insert(item).inserted { return item }
     }
     return nil
 }
 // The bad signature `func first<T: Equatable>(in array: [any Equatable]) -> T?`
 // makes T disconnected from the array elements: you can't safely cast
 // `any Equatable` back to T. The fix is to constrain the *array element*
 // type to T directly — `[T]` instead of `[any Equatable]`.

*/
