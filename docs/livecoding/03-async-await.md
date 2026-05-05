# 03 — async/await + Structured Concurrency

The biggest concurrency drill page. Coming from GCD, what bites senior devs hardest:

- (a) actor reentrancy
- (b) `Sendable`
- (c) `@MainActor` isolation inheritance
- (d) bounded `TaskGroup`
- (e) cancellation propagation
- (f) `AsyncStream` lifecycle

> Open side-by-side with `Playground/Livecoding.playground/Pages/03_AsyncAwait.xcplaygroundpage/Contents.swift`.

---

## Drill 1 — Where does `Task { }` actually run?  *(bug-hunt)*

GCD intuition: "spawn on a background queue."  
Swift Concurrency: "`Task { ... }` *inherits actor isolation from caller*."

Will the `downloadGigantic()` in the Swift file freeze the UI? Why? Fix without breaking actor isolation on `self.posts`.

---

## Drill 2 — Actor reentrancy bug  *(bug-hunt)*

The actor in the Swift file has a bug. Walk through (a) what's wrong, (b) how to fix without ditching the actor.

**Hint**: actors serialize *single steps*, but they are REENTRANT — every `await` is a suspension point.

---

## Drill 3 — Bounded parallelism  *(from-scratch)*

"Download these 50 URLs, max 5 in flight." Top-of-mind question.

- GCD instinct: `DispatchSemaphore` + `concurrentPerform`.
- Swift Concurrency: `TaskGroup` that primes N tasks, then enqueues one more whenever one finishes via `await group.next()`.

---

## Drill 4 — `Sendable` under Swift 6  *(bug-hunt)*

Compiler complains: "Capture of 'self' with non-Sendable type 'Cache' in a `@Sendable` closure." Cache is mutable. Show three options.

---

## Drill 5 — `AsyncStream` + cancellation  *(from-scratch)*

Wrap a callback-based "tick every 500ms" timer as `AsyncStream<Int>`:

- the consumer can cancel cleanly,
- the producer stops emitting as soon as the consumer's Task is cancelled.

---

## Drill 6 — `GlobalActor`  *(from-scratch)*

Define a `@DatabaseActor` global actor and use it to isolate two unrelated types (a free function and a struct) on the same shared actor instance — without those types holding a reference to it.

---

## Drill 7 — `isolated` parameters  *(from-scratch)*

Write a free function `bump(_ counter: isolated Counter)` that increments the actor's counter without `await` inside.

---

## Drill 8 — Task priority inheritance  *(bug-hunt)*

The intent: "run heavyWork at low priority so UI stays responsive." But heavyWork ends up running at userInitiated priority. Why? Fix it.

---

## Drill 9 — `AsyncSequence` vs Combine  *(from-scratch)*

Solve the same problem two ways:

- (a) Combine pipeline: emit `Int` every second, take 5.
- (b) AsyncSequence: yield `Int` every second, take 5.

Talk through the trade-offs.

---

## Drill 10 — Cancellation propagation  *(bug-hunt)*

The function in the Swift file is "cancellable" (parent task gets cancelled), but the for-loop never observes it and runs to completion. Fix it.

---

## Drill 11 — `async let` lifetime  *(bug-hunt)*

Spot the issue: `async let banner = ...` is created but never awaited. What happens at the closing brace?

---

## Drill 12 — `@MainActor` in `init`  *(from-scratch)*

Make the `@MainActor` class in the Swift file constructible from a non-MainActor context (e.g., from inside a background actor or `Task.detached`).
