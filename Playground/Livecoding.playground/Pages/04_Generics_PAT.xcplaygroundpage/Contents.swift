/*:
 # 04 — Generics, PAT, opaque vs existential, advanced type system

 Senior trap: confusing `some Protocol` (opaque, single concrete type
 hidden from caller) with `any Protocol` (existential box, type erased
 at runtime). Plus PATs, type erasers, KeyPath, conditional conformance,
 dynamicMemberLookup.

 ----
 */
import Foundation

// MARK: - Drill 1: some vs any

/*:
 ### Prompt 1 — discussion
 Walk through the runtime cost and call-site implications of each:
 ```swift
 func a() -> Animal { ... }       // implicit any (pre-Swift 5.7)
 func b() -> some Animal { ... }
 func c() -> any Animal { ... }
 ```
 No code — talk through it.
 */

// (verbal answer at the bottom)

// MARK: - Drill 2: Why doesn't this compile?

/*:
 ### Prompt 2 — bug-hunt
 ```
 protocol DataSource {
     associatedtype Item
     func load() async throws -> [Item]
 }
 // Compiler rejects this:
 // func makeSources() -> [DataSource] { [LocalUsers(), RemoteFlags()] }
 ```
 Why, and what's the minimum fix?
 */

protocol DataSource_Bad {
    associatedtype Item
    func load() async throws -> [Item]
}

struct LocalUsers: DataSource_Bad {
    func load() async throws -> [String] { ["Ana", "Beto"] }
}
struct RemoteFlags: DataSource_Bad {
    func load() async throws -> [Bool] { [true, false] }
}

// TODO: write a function returning a heterogeneous collection of DataSources.

// MARK: - Drill 3: Type eraser by hand

/*:
 ### Prompt 3 — from-scratch
 The standard library has `AnySequence`, `AnyPublisher`. Build
 `AnyDataSource<Item>` — a manual type eraser that hides the concrete
 type but preserves `Item`.
 */

protocol DataSource {
    associatedtype Item
    func load() async throws -> [Item]
}

// TODO: struct AnyDataSource<Item> { ... }

// MARK: - Drill 4: Primary associated types

/*:
 ### Prompt 4 — from-scratch
 Swift 5.7 introduced primary associated types. Show both:
 - "any Sequence whose Element is Int" — function parameter
 - "some Collection where Element is String" — function parameter
 */

// TODO: function signatures using `some Collection<String>`
// TODO: function using `any Sequence<Int>`

// MARK: - Drill 5: firstDuplicate generic

/*:
 ### Prompt 5 — bug-hunt → from-scratch
 The interviewer asks: "Why doesn't this work?"
 ```swift
 func first<T: Equatable>(in array: [any Equatable]) -> T? { ... }
 ```
 They want to hear: existentials erase per-element type.

 Now write the CORRECT signature for `firstDuplicate(_:)`.
 */

// TODO: func firstDuplicate<T: Hashable>(_ items: [T]) -> T?

// MARK: - Drill 6: KeyPath flavors

/*:
 ### Prompt 6 — from-scratch
 Show one of each: `KeyPath`, `WritableKeyPath`, `ReferenceWritableKeyPath`,
 and a generic helper that ONLY accepts `ReferenceWritableKeyPath`.
 */

struct Person { var name: String }
final class Account { var balance: Int = 0 }

// TODO:
// let nameKey: WritableKeyPath<Person, String> = ...
// let balanceKey: ReferenceWritableKeyPath<Account, Int> = ...
// func bump<R: AnyObject>(_ root: R, _ kp: ReferenceWritableKeyPath<R, Int>) { ... }

// MARK: - Drill 7: Conditional conformance

/*:
 ### Prompt 7 — from-scratch
 Make `Box<T>` conform to `Equatable` and `Hashable` ONLY when `T`
 conforms to those.
 */

struct Box<T> { let value: T }

// TODO: extension Box: Equatable where T: Equatable { ... }
// TODO: extension Box: Hashable where T: Hashable { ... }

// MARK: - Drill 8: where Self: SomeProtocol

/*:
 ### Prompt 8 — from-scratch
 Add `func sum() -> Element` to `Sequence` ONLY when `Element: Numeric`.
 */

// TODO: extension Sequence where Element: Numeric { func sum() -> Element { ... } }

// MARK: - Drill 9: dynamicMemberLookup

/*:
 ### Prompt 9 — from-scratch
 Build a `Box<T>` with `@dynamicMemberLookup` that forwards properties
 of `T` (read-only is fine). Show that `box.someProperty` works as if
 you accessed `box.wrapped.someProperty`.
 */

// TODO:
// @dynamicMemberLookup
// struct Box<T> {
//     var wrapped: T
//     subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U { ... }
// }

/*

 ============================================================================
 SOLUTIONS
 ============================================================================

 // ----- Drill 1: some vs any -----
 //
 // | Form          | Concrete type known at compile time? | Runtime box? | Heterogeneous coll? | Static dispatch? |
 // | ------------- | ------------------------------------ | ------------ | ------------------- | ---------------- |
 // | some P        | YES (caller doesn't see, compiler does) | no           | NO                  | YES              |
 // | any P         | NO (carried in existential at runtime) | yes          | YES                 | NO (witness)     |
 // | bare P (<5.7) | implicit any P                       | yes          | yes                 | no               |

 // ----- Drill 2: heterogeneous PATs -----
 // Won't compile: [DataSource_Bad] would need a single associated type,
 // but LocalUsers.Item != RemoteFlags.Item.
 //
 // Fix A: primary associated types — only works if all sources share Item.
 //   protocol DataSource_Bad<Item> { associatedtype Item; ... }
 //   func makeSources() -> [any DataSource_Bad<String>]
 //
 // Fix B: type-erase to AnyDataSource (next drill).

 // ----- Drill 3: AnyDataSource -----
 struct AnyDataSource<Item> {
     private let _load: () async throws -> [Item]
     init<S: DataSource>(_ source: S) where S.Item == Item {
         self._load = source.load
     }
     func load() async throws -> [Item] { try await _load() }
 }
 // Now [AnyDataSource<String>] is fine.

 // ----- Drill 4: primary associated types -----
 func process(items: any Sequence<Int>) -> Int { items.reduce(0, +) }
 func toUpper(items: some Collection<String>) -> [String] {
     items.map { $0.uppercased() }
 }

 // ----- Drill 5: firstDuplicate -----
 func firstDuplicate<T: Hashable>(_ items: [T]) -> T? {
     var seen = Set<T>()
     for item in items {
         if !seen.insert(item).inserted { return item }
     }
     return nil
 }

 // ----- Drill 6: KeyPath flavors -----
 let nameKey: WritableKeyPath<Person, String> = \Person.name
 let balanceKey: ReferenceWritableKeyPath<Account, Int> = \Account.balance

 var p = Person(name: "Ana")
 p[keyPath: nameKey] = "Bia"

 let acc = Account()              // `let` works for class!
 acc[keyPath: balanceKey] = 100   // OK — write through reference

 func bump<R: AnyObject>(_ root: R, _ kp: ReferenceWritableKeyPath<R, Int>) {
     root[keyPath: kp] += 1
 }

 // ----- Drill 7: Conditional conformance -----
 extension Box: Equatable where T: Equatable {
     static func == (lhs: Box<T>, rhs: Box<T>) -> Bool { lhs.value == rhs.value }
 }
 extension Box: Hashable where T: Hashable {
     func hash(into hasher: inout Hasher) { hasher.combine(value) }
 }
 // Box<Int> can go in Set; Box<UIView> can't.

 // ----- Drill 8: where Self: ... -----
 extension Sequence where Element: Numeric {
     func sum() -> Element { reduce(.zero, +) }
 }
 // [1, 2, 3].sum() works.
 // ["a", "b"].sum() doesn't compile.

 // ----- Drill 9: dynamicMemberLookup -----
 @dynamicMemberLookup
 struct DynamicBox<T> {
     var wrapped: T
     subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U {
         wrapped[keyPath: keyPath]
     }
 }
 struct User { let name: String; let age: Int }
 let box = DynamicBox(wrapped: User(name: "Ana", age: 30))
 // box.name => "Ana" — forwarded
 // box.foo => compile error (no KeyPath<User, _> for foo)

*/
