# 3-day senior iOS interview plan

**Constraint**: 2–3h per night, total 6–9h.
**Target interview**: 1h conversational + livecoding.
**Baseline**: ~6 years UIKit/Obj-C, never shipped SwiftUI.

This plan is brutally focused. You won't "learn SwiftUI" in 3 days — you'll learn **enough to articulate trade-offs and write small pieces** under interviewer pressure. That's what passes the round.

> ⚠️ **Don't try to read the whole codebase.** Each session below is a 2-hour box. Stick to it; close the laptop when the timer rings.

---

## Day 1 — SwiftUI mental model + async/await fundamentals (2.5h)

Goal: be able to explain `@State`/`@Binding`/`@Observable` and `Task` isolation in plain English, and write a small SwiftUI screen from scratch.

### 0:00–0:20 — Read (don't skim)

- `docs/livecoding/01-swiftui-fundamentals.md` (mental model section)
- `docs/livecoding/03-async-await.md` (intro — drills 1, 2, 5)
- Skip everything else for now.

### 0:20–1:00 — Drill: SwiftUI fundamentals

Open `Playground/Livecoding.playground`, page **01**, ⌥⌘↵ for live view.

- **Page1Exercise1View** — Counter + StepperRow. Type from scratch, don't peek at solution. (~15 min)
- **Page1Exercise2View** — Find the `id:` bug. Walk it out loud. (~5 min)
- **Page1Exercise3View** — UIKit→SwiftUI port. Type from scratch. (~20 min)

If you finish early, **don't speed up** — re-do Drill 1 a second time, faster, narrating your reasoning. Repetition while talking is the actual skill.

### 1:00–1:30 — Quiz reps (Beon-style)

Open the Mac app (`open SwiftUIInterview.xcodeproj`, pick **My Mac (Mac Catalyst)**, ⌘R).

- Answer 10 questions from **SwiftUI** and **Concurrency** topics.
- For each: pick answer → reveal → **read explanation OUT LOUD** as if explaining to interviewer.
- Track score in a notepad.

### 1:30–2:30 — Drill: async/await

Page **03** of Livecoding playground.

- **Page3 Drill 1** (where Task runs) — type the `Task.detached` fix. (~15 min)
- **Page3 Drill 2** (actor reentrancy) — type the snapshot fix. Explain WHY out loud. (~15 min)
- **Page3 Drill 5** (AsyncStream cleanup) — type from scratch. This one is the spaced one — try, peek, re-type. (~30 min)

### Day 1 self-check (5 min, before bed)

Out loud, answer:

1. "When does SwiftUI tear down `@State`?"
2. "What does `Task { }` inherit from its caller?"
3. "Why is `actor` reentrant a problem?"

If you can't answer one in <30s, re-read the relevant page tomorrow morning before work.

---

## Day 2 — SwiftUI intermediate + Architecture talking points (2.5h)

Goal: handle the "where does X live in MVVM?" questions and write a non-trivial SwiftUI screen with state, navigation, and a custom modifier.

### 0:00–0:20 — Read

- `docs/livecoding/02-swiftui-intermediate.md` (drills 1, 3, 5)
- `docs/livecoding/05-arc-memory.md` (drill 1 — Combine cycle)
- `docs/Architecture-Patterns.md` (MVVM + Repository sections only, ~10 min)

### 0:20–1:30 — Drill: SwiftUI intermediate

Page **02** of Livecoding playground.

- **Page2Exercise1View** — Environment-based DI. Implement EnvironmentKey + `@Environment` reader. (~20 min)
- **Page2Exercise3** (RoundedShadowStyle modifier) — type the ViewModifier + View extension. (~15 min)
- **Page2Exercise5View** — Data-driven nav with VM. (~25 min)
- **Page2Exercise8View** — Find the bug (missing `.navigationDestination(for:)`). (~10 min)

Update the live preview block at the bottom to show whichever view you just finished. Run, see it work.

### 1:30–2:00 — Quiz reps

- 10 questions on **Architecture** topic (focus on MVVM/TCA, DI, navigation, repository).
- Same routine: read explanation out loud.

### 2:00–2:30 — Mock interview (alone, talking out loud)

Pick **3 quiz questions you got wrong yesterday or today**. For each:

1. Pretend the interviewer just asked it.
2. **Talk through your answer for 60 seconds**, narrating reasoning.
3. Then look at the explanation. Note where you went off.

This is the most uncomfortable part of the plan and the most important. **Do not skip.**

### Day 2 self-check (5 min)

Out loud:

1. "How do you inject a service into 5 nested SwiftUI views?"
2. "Where does navigation state live in MVVM SwiftUI?"
3. "Spot a Combine retain cycle in 10 seconds."

---

## Day 3 — Livecoding under pressure + 1 mock + final review (2.5h)

Goal: simulate the real interview. Write code while explaining. Identify 2-3 weakest topics for the morning of the interview.

### 0:00–0:30 — Quick warm-up

- 10 quiz questions, mixed topics. Quick pace.
- Don't worry about score — this is to get your brain in "interview mode."

### 0:30–1:30 — Full mock livecoding (60 min, timed)

Pick **one** of these. Set a 30-min timer per problem. Explain everything OUT LOUD as you type. Use the Livecoding playground.

**Problem A** (Page2Exercise5View — data-driven nav):
> "Build a SwiftUI feed view: list of posts, tap pushes detail. Navigation state lives in a view-model, not in `@State`. Use `@Observable` (iOS 17+)."

**Problem B** (Page3 Drill 3 — bounded TaskGroup):
> "Download 50 image URLs concurrently, max 5 in flight. Use Swift Concurrency, no GCD."

**Problem C** (Page6 Drill 1 — Debouncer):
> "Build an `actor Debouncer` that schedules an action `delay` after the LAST call. Cancellable."

For whichever you pick:
- 0–5 min: clarify out loud what you'd build, draw the type signatures.
- 5–25 min: type. Narrate trade-offs as you go.
- 25–30 min: review code, find one bug, explain it.

### 1:30–2:00 — Review YOUR mock

Compare what you wrote to the SOLUTIONS block at the bottom of the page. Identify:

- 1 thing you got right that you'd say better next time.
- 1 thing you missed (often: cancellation, retain cycle, identity).

### 2:00–2:30 — Targeted gap fix

Based on quiz scores from Days 1–2 + the mock above, pick **the 1 weakest topic** and:

- Re-read its `docs/livecoding/0X.md`.
- Re-do its quiz questions.
- Type its hardest drill once more, fresh.

### Final pre-interview self-check

Be able to talk for 60 seconds about each:

| Topic | One-line you must own |
|---|---|
| `@State` vs `@Binding` vs `@Observable` | Local truth, two-way handle to remote, class shared model |
| `.task` vs `.onAppear` | task auto-cancels on disappear; onAppear+Task leaks |
| `Task { }` inheritance | Inherits actor isolation + priority + task locals |
| `withTaskGroup` bounded parallelism | Prime N, drain with `for await`, enqueue one more on each finish |
| Actor reentrancy | Awaits inside actor methods are suspension points; snapshot before await |
| MVVM navigation | Intent in VM as state, View binds; multi-step flows → Coordinator |
| Environment DI | EnvironmentKey + `.environment(\.api, ...)` + `@Environment(\.api)` |
| Combine retain cycle | publisher→closure→self→AnyCancellable→publisher; `[weak self]` |

If any line above feels shaky, that's your 30-minute morning review the day of the interview.

---

## What NOT to study (in 3 days)

You **will not** be a Combine expert, a SwiftData expert, or a Swift macros author. The interviewer knows you're senior — they care about **judgment**, not encyclopedic recall.

- Skip Combine deep-dive (drill 1 of page 05 is enough — just know the cycle).
- Skip macros internals.
- Skip `@dynamicMemberLookup`, conditional conformance, KeyPath flavors — page 04 drills 6–9 are nice-to-haves, not essentials.
- Skip property wrapper composition (page 05 drill 6).
- Skip TCA — be able to mention it as an alternative ("for complex state machines"), nothing deeper.

If interviewer drills into one of these, **say honestly** "I haven't shipped that in production; here's how I'd reason about it" — that's a senior answer. Faking knowledge is the only thing that genuinely tanks a senior round.

---

## Day-of-interview morning (30 min)

1. Re-read the 8-line table above out loud.
2. Open `Playground/Livecoding.playground`, page 01, type Drill 1 from memory in 5 minutes.
3. **Stop studying** 30 min before the call. Take a walk.
