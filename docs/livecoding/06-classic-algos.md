# 06 — Classic livecoding problems in Swift

Seven problems senior iOS screens love. Each is small enough to whiteboard in 15-25 min while you talk through trade-offs.

> Open side-by-side with `Playground/Livecoding.playground/Pages/06_Classic_Algos.xcplaygroundpage/Contents.swift`.

---

## Drill 1 — Debounce a function

Build a debouncer: given a delay, return a function that, when called repeatedly, only fires the action `delay` after the LAST call.

Constraints:

- thread-safe (think: typing in a search box, multiple keystrokes from main).
- cancellable.
- Use Swift Concurrency, not GCD.

---

## Drill 2 — LRU Cache

Build an `LRUCache<Key: Hashable, Value>` with O(1) get + O(1) set, evicting the least-recently-used entry when capacity is reached.

Mental model: hashmap + doubly-linked list. The hashmap maps key→node; the list maintains order; "recent" goes to head.

Don't reach for stdlib `OrderedDictionary` — write the doubly-linked list yourself.

---

## Drill 3 — Async semaphore

GCD has `DispatchSemaphore`. Swift Concurrency does NOT — `wait()` would block, defeating cooperative scheduling.

Build an `AsyncSemaphore` with `wait()` and `signal()` that:

- allows up to N concurrent acquirers (bounded permits),
- suspends excess acquirers (no busy-wait),
- resumes them in FIFO order on signal.

---

## Drill 4 — Throttle (leading edge)

Different from debounce: throttle FIRES IMMEDIATELY on the first call in a window, then ignores further calls until `interval` elapses. (Think: don't let the user spam-tap "Send".)

---

## Drill 5 — Custom AsyncSequence

Build a `CountdownSequence: AsyncSequence` that yields `Int` from N down to 0 with a configurable delay between elements. Make it Sendable-clean.

---

## Drill 6 — Composite + Factory

Build an `AnalyticsService` protocol with two concrete implementations (Firebase, Mixpanel) plus a `CompositeAnalytics` that fans out to all of them. Show how you'd build the right composition at startup based on a feature flag.

---

## Drill 7 — Deep link parser

Build a `DeepLinkParser` that turns these URLs into typed `Route` values:

- `myapp://profile/abc123` → `.profile("abc123")`
- `myapp://post/<UUID>` → `.post(uuid)`
- anything else → `nil`

Show a unit test that round-trips one of each.
