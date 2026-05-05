# 05 — ARC, retain cycles, and copy-on-write

Memory questions are senior gates. Six years of UIKit experience helps, but interviewers love the *Combine + closure* combos that didn't exist in early Swift, plus property wrapper composition and `AnyHashable`.

> Open side-by-side with `Playground/Livecoding.playground/Pages/05_ARC_Memory.xcplaygroundpage/Contents.swift`.

---

## Drill 1 — Spot the cycle  *(bug-hunt)*

Does the code in the Swift file leak? If yes, fix it without changing the public API.

---

## Drill 2 — `weak` vs `unowned`  *(discussion)*

You replace `self.results = ...` with `[weak self]` + `self?.results = ...`. The interviewer asks: "Why didn't you use `[unowned self]`? It's faster."

When is each correct?

---

## Drill 3 — Copy-on-Write — does this copy?  *(discussion)*

```swift
var a = Array(repeating: 1, count: 1_000_000)
var b = a       // ① copies?
b.append(2)     // ② copies?
print(a.count)  // ③ outputs?
```

Walk through what happens at each step.

---

## Drill 4 — Build CoW from scratch  *(from-scratch)*

Implement a value type `Buffer` that holds a class-backed `Storage` and only clones storage when mutated AND the storage is shared. Magic word: `isKnownUniquelyReferenced`.

---

## Drill 5 — Closure capturing in Swift Concurrency  *(discussion)*

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

Same retain-cycle worry as the Combine sink? Hint: NO — explain why `Task { }` is different from a stored closure.

---

## Drill 6 — Property wrapper composition  *(bug-hunt → from-scratch)*

You write `@Published @SomeWrapper var x: Int = 0` in a class. Order of the wrappers matters — explain how nesting works, and write a tiny `@Clamped` wrapper that composes correctly with another wrapper.

---

## Drill 7 — `AnyHashable` performance  *(discussion)*

When does `[AnyHashable: Any]` bite you? When is it the right tool?
