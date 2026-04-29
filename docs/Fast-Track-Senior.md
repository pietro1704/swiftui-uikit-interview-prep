# ⚡️ 4-Day Fast Track for Senior iOS Engineers

> Designed for engineers with 5+ years of iOS experience who want maximum signal in minimum time. Each day is ~4-6 hours of focused work.
>
> Skip the parts you've shipped to production a hundred times. Spend your time on what's *new* (Observation, structured concurrency, SwiftData) and what you'll be tested on (advanced UIKit, interop, gotchas).

---

## Day 1 — Modern SwiftUI mental model

**Goal:** internalize how SwiftUI thinks differently from UIKit (declarative, value-based, diff-driven), and master the new state primitives.

| Time | Activity |
|------|----------|
| 60 min | **Lessons 1-3** at 2× speed. Don't dwell — you know UIs. Focus on the *differences* from UIKit: declarative re-render, `body: some View` opaque types, NavigationStack path. |
| 60 min | **Lesson 5 (@Observable + MVVM)**. Understand why `@Observable` replaced `ObservableObject`: per-keypath tracking, no `@Published`. Read the [Observation framework docs](https://developer.apple.com/documentation/observation). |
| 60 min | **Lesson 13 (Advanced SwiftUI)**. PreferenceKey, GeometryReader, custom ViewModifier, custom `EnvironmentValues`. These are sr-level interview gold. |
| 30 min | **Form + Animations** (Lessons 4 + 8). Skim. |
| 60 min | **Mock interview**: pick 5 SwiftUI questions from [Interview-Questions](Interview-Questions.md) and answer them out loud in 3 min each. |

**Day 1 deliverable:** Solve the TODO in Lesson 5 (custom `Clock` protocol injected into the ViewModel for testable time).

---

## Day 2 — Concurrency at depth

**Goal:** speak confidently about Swift's structured concurrency model, including the parts that trip people up (reentrancy, Sendable, isolation).

| Time | Activity |
|------|----------|
| 60 min | **Lesson 6 (async/await + URLSession)**. State modelling, `.task` lifecycle, cancellation. |
| 90 min | **Lesson 14 (Advanced concurrency)** — *the one that matters*. Master: `async let` vs `TaskGroup`, actors and reentrancy, `@MainActor`, `AsyncStream`, `Sendable`, structured cancellation. |
| 30 min | **Lesson 7 (Combine)**. Skim — know when to reach for Combine vs async/await. |
| 60 min | Read Apple's [WWDC 2021 session "Swift concurrency: Behind the scenes"](https://developer.apple.com/videos/play/wwdc2021/10254/) and the [Sendable proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md). |
| 60 min | **Mock interview**: 5 concurrency questions, 3 min each. Force yourself to draw on paper. |

**Day 2 deliverable:** Solve the TODO in Lesson 14 (convert `ImageCache` to use `NSCache` while remaining an actor; add fail-fast `withThrowingTaskGroup`).

---

## Day 3 — UIKit advanced + interop

**Goal:** prove you can ship UIKit code at a high level and bridge it cleanly into SwiftUI (still very common in real codebases).

| Time | Activity |
|------|----------|
| 30 min | Skim **Lesson 11 (Interop)** — Representable, Coordinator, HostingController. Mostly review for you. |
| 90 min | **Lesson 12 (Advanced UIKit)** — Compositional Layout, Diffable Data Source, custom UIControl. Even if you've used these, solve the TODOs (supplementary headers, accessibility traits). |
| 30 min | Re-read the [UIKit Cheat Sheet](Cheat-Sheet-UIKit.md). Drill the lifecycle order from memory. |
| 60 min | **Lesson 9 (SwiftData)**. New since Core Data — know the `@Model` / `@Query` / `ModelContext` triad and how it differs from CD (no `NSManagedObjectContext` directly, no fetch requests). |
| 60 min | **Mock interview**: 5 UIKit + 5 interop questions, 3 min each. |

**Day 3 deliverable:** Add a working `UIPageViewController` wrapper to Lesson 11 + a `UICollectionViewDelegate` to Lesson 12.

---

## Day 4 — Synthesis, gotchas, system design

**Goal:** sharpen the soft parts (architecture, debugging, performance) and run a full mock loop.

| Time | Activity |
|------|----------|
| 60 min | **[Common Pitfalls](Common-Pitfalls.md)** — read all of them, especially memory & concurrency. These are the "trick questions". |
| 60 min | **[Architecture Patterns](Architecture-Patterns.md)** — formulate your *opinion*: when do you reach for MVVM vs TCA vs Coordinator? Be ready to defend it. |
| 30 min | **Lesson 10 (Testing)**. Solve all TODOs. |
| 60 min | **System design dry run**: take a hypothetical "build a chat app" / "build an offline-first feed reader" and design it on paper in 30 min. Then critique your own design. |
| 90 min | **Full mock loop**: 30 min coding (live-code Lesson 12's TODO from scratch), 30 min concurrency Q&A, 30 min architecture discussion. Time yourself. |

**Day 4 deliverable:** A short markdown note on *your own* architectural opinions. Bring it to the interview.

---

## What to skip if you're truly tight on time

- Lesson 2 (Lists) — you've done this 1000 times
- Lesson 3 (NavigationStack) — read the cheat sheet, move on
- Lesson 4 (Forms) — same
- Lesson 7 (Combine) — only if the company uses it; otherwise async/await replaces 80% of usage

## What you should *not* skip

- Lesson 5 (`@Observable`) — high probability they'll ask why this is better than `ObservableObject`
- Lesson 13 (Advanced SwiftUI) — separates seniors from mid-levels
- Lesson 14 (Advanced concurrency) — almost guaranteed deep dive
- Lesson 12 (Advanced UIKit) — Diffable + Compositional are table-stakes for senior UIKit
- All of [Common Pitfalls](Common-Pitfalls.md) — the gotcha questions

---

> 🎯 **Interview-day reminder**: it's better to say "I'm not 100% sure but I'd guess X because Y" than to fake confidence. Senior engineers are expected to reason out loud, not memorize.
