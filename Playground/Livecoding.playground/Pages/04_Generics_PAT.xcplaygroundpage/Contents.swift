// Page 04 — Generics, PAT, opaque vs existential, advanced type system
// Read prompts/explanations: ../../../../docs/livecoding/04-generics-pat.md

import Foundation

// MARK: Drill 1 — some vs any (discussion — verbal)

// MARK: Drill 2 — Why doesn't this compile? (bug-hunt)

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

// MARK: Drill 3 — Type eraser by hand

protocol DataSource {
    associatedtype Item
    func load() async throws -> [Item]
}
// TODO: struct AnyDataSource<Item> { ... }

// MARK: Drill 4 — Primary associated types

// TODO: function signatures using `some Collection<String>` and `any Sequence<Int>`

// MARK: Drill 5 — firstDuplicate generic (bug-hunt → from-scratch)

// TODO: func firstDuplicate<T: Hashable>(_ items: [T]) -> T?

// MARK: Drill 6 — KeyPath flavors

struct Person { var name: String }
final class Account { var balance: Int = 0 }

// TODO:
// let nameKey: WritableKeyPath<Person, String> = ...
// let balanceKey: ReferenceWritableKeyPath<Account, Int> = ...
// func bump<R: AnyObject>(_ root: R, _ kp: ReferenceWritableKeyPath<R, Int>) { ... }

// MARK: Drill 7 — Conditional conformance

struct Box<T> { let value: T }
// TODO: extension Box: Equatable where T: Equatable { ... }
// TODO: extension Box: Hashable where T: Hashable { ... }

// MARK: Drill 8 — where Self: SomeProtocol

// TODO: extension Sequence where Element: Numeric { func sum() -> Element { ... } }

// MARK: Drill 9 — dynamicMemberLookup

// TODO:
// @dynamicMemberLookup
// struct DynamicBox<T> {
//     var wrapped: T
//     subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U { ... }
// }

/*

================================================================================
SOLUTIONS
================================================================================

// ----- Drill 1: some vs any cheat-sheet -----
//
// | Form          | Concrete type at compile time? | Runtime box? | Heterogeneous coll? | Static dispatch? |
// | ------------- | ------------------------------ | ------------ | ------------------- | ---------------- |
// | some P        | YES (hidden from caller)       | no           | NO                  | YES              |
// | any P         | NO (carried in existential)    | yes          | YES                 | NO (witness)     |
// | bare P (<5.7) | implicit any P                 | yes          | yes                 | no               |

// ----- Drill 2 -----
// Won't compile: [DataSource_Bad] would need a single associated type,
// but LocalUsers.Item != RemoteFlags.Item.
//
// Fix A (Swift 5.7+): primary associated types — only works if all share Item.
//   protocol DataSource_Bad<Item> { associatedtype Item; ... }
//   func makeSources() -> [any DataSource_Bad<String>]
// Fix B: type-erase to AnyDataSource (next drill).

// ----- Drill 3 -----
struct AnyDataSource<Item> {
    private let _load: () async throws -> [Item]
    init<S: DataSource>(_ source: S) where S.Item == Item {
        self._load = source.load
    }
    func load() async throws -> [Item] { try await _load() }
}

// ----- Drill 4 -----
func process(items: any Sequence<Int>) -> Int { items.reduce(0, +) }
func toUpper(items: some Collection<String>) -> [String] {
    items.map { $0.uppercased() }
}

// ----- Drill 5 -----
func firstDuplicate<T: Hashable>(_ items: [T]) -> T? {
    var seen = Set<T>()
    for item in items {
        if !seen.insert(item).inserted { return item }
    }
    return nil
}

// ----- Drill 6 -----
let nameKey: WritableKeyPath<Person, String> = \Person.name
let balanceKey: ReferenceWritableKeyPath<Account, Int> = \Account.balance

var p = Person(name: "Ana")
p[keyPath: nameKey] = "Bia"

let acc = Account()
acc[keyPath: balanceKey] = 100   // OK on `let` — class write through reference

func bump<R: AnyObject>(_ root: R, _ kp: ReferenceWritableKeyPath<R, Int>) {
    root[keyPath: kp] += 1
}

// ----- Drill 7 -----
extension Box: Equatable where T: Equatable {
    static func == (lhs: Box<T>, rhs: Box<T>) -> Bool { lhs.value == rhs.value }
}
extension Box: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(value) }
}

// ----- Drill 8 -----
extension Sequence where Element: Numeric {
    func sum() -> Element { reduce(.zero, +) }
}

// ----- Drill 9 -----
@dynamicMemberLookup
struct DynamicBox<T> {
    var wrapped: T
    subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U {
        wrapped[keyPath: keyPath]
    }
}
struct User { let name: String; let age: Int }
let box = DynamicBox(wrapped: User(name: "Ana", age: 30))
// box.name => "Ana"; box.foo => compile error.

*/
