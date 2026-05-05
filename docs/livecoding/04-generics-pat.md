# 04 — Generics, PAT, opaque vs existential, advanced type system

Senior trap: confusing `some Protocol` (opaque, single concrete type hidden from caller) with `any Protocol` (existential box, type erased at runtime). Plus PATs, type erasers, KeyPath, conditional conformance, `dynamicMemberLookup`.

> Open side-by-side with `Playground/Livecoding.playground/Pages/04_Generics_PAT.xcplaygroundpage/Contents.swift`.

---

## Drill 1 — `some` vs `any`  *(discussion)*

Walk through the runtime cost and call-site implications of each:

```swift
func a() -> Animal { ... }       // implicit any (pre-Swift 5.7)
func b() -> some Animal { ... }
func c() -> any Animal { ... }
```

No code — talk through it.

---

## Drill 2 — Why doesn't this compile?  *(bug-hunt)*

```swift
protocol DataSource {
    associatedtype Item
    func load() async throws -> [Item]
}
// Compiler rejects this:
// func makeSources() -> [DataSource] { [LocalUsers(), RemoteFlags()] }
```

Why, and what's the minimum fix?

---

## Drill 3 — Type eraser by hand  *(from-scratch)*

The standard library has `AnySequence`, `AnyPublisher`. Build `AnyDataSource<Item>` — a manual type eraser that hides the concrete type but preserves `Item`.

---

## Drill 4 — Primary associated types  *(from-scratch)*

Swift 5.7 introduced primary associated types. Show both:

- "any Sequence whose Element is Int" — function parameter
- "some Collection where Element is String" — function parameter

---

## Drill 5 — `firstDuplicate` generic  *(bug-hunt → from-scratch)*

The interviewer asks: "Why doesn't this work?"

```swift
func first<T: Equatable>(in array: [any Equatable]) -> T? { ... }
```

They want to hear: existentials erase per-element type. Now write the CORRECT signature for `firstDuplicate(_:)`.

---

## Drill 6 — KeyPath flavors  *(from-scratch)*

Show one of each: `KeyPath`, `WritableKeyPath`, `ReferenceWritableKeyPath`, and a generic helper that ONLY accepts `ReferenceWritableKeyPath`.

---

## Drill 7 — Conditional conformance  *(from-scratch)*

Make `Box<T>` conform to `Equatable` and `Hashable` ONLY when `T` conforms to those.

---

## Drill 8 — `where Self: SomeProtocol`  *(from-scratch)*

Add `func sum() -> Element` to `Sequence` ONLY when `Element: Numeric`.

---

## Drill 9 — `dynamicMemberLookup`  *(from-scratch)*

Build a `Box<T>` with `@dynamicMemberLookup` that forwards properties of `T` (read-only is fine). Show that `box.someProperty` works as if you accessed `box.wrapped.someProperty`.
