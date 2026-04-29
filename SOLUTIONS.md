# 🔑 Solutions branch

This branch contains worked solutions to the lesson exercises so you can compare
your own answers after attempting them on `main`.

> ⚠️ **Try the exercise first.** Reading a solution before struggling with the
> problem destroys the entire point of the playground.

## Solved here

| Lesson | What you'll find |
|--------|------------------|
| 01 — `@State` & `@Binding` | `StepperRow` subview using `@Binding`, plus a "Reset all" button |
| 05 — MVVM | `undo()` on the `CounterViewModel` |
| 10 — Testing | Three additional XCTest cases covering decrement floor, history sequence, and undo |

## Solving the rest

Most remaining exercises follow these patterns:

- **Lessons 2-4 (Lists / Navigation / Forms)** — UI-mechanical, follow Apple's docs
- **Lesson 6 (async/await)** — wrap the load in `Task`, store the handle, call `.cancel()`
- **Lessons 11-12 (UIKit)** — read the comments inside the file; each exercise has a hint
- **Lesson 14 (Concurrency)** — solutions live in `withThrowingTaskGroup` / `Task.checkCancellation()` — search the Swift Concurrency docs

## Reading a solution

```bash
git checkout solutions
# inspect the file in question, e.g.:
git diff main solutions -- SwiftUIInterview/Lessons/Lesson01_StateBinding.swift
git checkout main          # back to the unsolved version
```

## Want to add more?

PRs welcome. Keep the solution faithful to the lesson's didactic intent — don't
over-engineer or introduce concepts the lesson hasn't covered yet.
