# 01 — SwiftUI Fundamentals (livecoding drills)

Builds the SwiftUI mental model from zero so you can reason out loud during a livecoding round. Useful even after years of UIKit — the declarative paradigm flips a lot of intuitions.

> Open this side-by-side with `Playground/Livecoding.playground/Pages/01_SwiftUI_Fundamentals.xcplaygroundpage/Contents.swift`. The Swift file has the skeletons + reference solutions; this `.md` has the prompts and explanations.

## How to use this page

Each drill has:

1. **Prompt** — what you'd be asked to produce.
2. **Skeleton** — empty signature you fill in (in the Swift file).
3. **Talk-track** — sentences to say while typing.
4. **Solution** — at the bottom of the Swift file, in a `/* … */` block. Don't peek.

## Mental model — read first

SwiftUI views are **value types describing the UI**, not the UI itself. SwiftUI calls `body` whenever the view's input changes; the framework diffs the resulting tree and updates the screen.

Three property wrappers cover 95% of state:

- `@State` — local source of truth, owned by the view.
- `@Binding` — a two-way handle to state owned somewhere else.
- `@Observable` (iOS 17+) — class-based, for shared models / VMs.

**Identity rule**: SwiftUI keeps `@State` alive as long as the view's *position + type + explicit `.id()`* match across body re-evaluations. Change any of those and `@State` resets.

---

## Drill 1 — Counter with extracted child  *(from-scratch)*

Build a `CounterView` showing a number and `+` / `-` buttons. Then extract a `StepperRow` subview that takes a `@Binding<Int>` and renders the buttons. Parent owns state, child only mutates it.

**Talk-track**:

> Parent owns `@State count`, passes `$count` as `@Binding` to the child. The child mutates via `value -= 1`; SwiftUI propagates the change up automatically because Binding is a two-way reference.

---

## Drill 2 — Why doesn't this list animate?  *(bug-hunt)*

The list visibly "jumps" instead of animating row insertions. The interviewer asks: **why?** Fix without rewriting the data model.

**Hint:** look at the `id:` parameter on `ForEach`.

---

## Drill 3 — Convert this UIKit thinking to SwiftUI  *(port)*

An interviewer pastes pseudo-UIKit:

```
// viewModel has @Published var query: String
// textField.delegate = self
// func textField(...didChange...) { viewModel.query = text }
// viewModel.$query.sink { results in self.tableView.reloadData() }
```

Re-express as a SwiftUI view. No Combine. Use `@Observable` macro.

**Talk-track**: "In SwiftUI, the binding `$vm.query` is a *two-way handle* to the property — typing into the TextField writes through, and the body re-evaluates whenever an `@Observable` keypath I read changes."

---

## Drill 4 — `.task` vs `.onAppear`  *(bug-hunt)*

The view in the Swift file leaks: dismissing it mid-load still hits `posts = ...` after the network completes. Pick the right SwiftUI modifier so the load is cancelled when the view disappears.

---

## Drill 5 — `@Bindable` for child editing parent's `@Observable`  *(bug-hunt)*

The child view can't compile `$user.name`. Fix it without removing the `@Observable` model.

---

## Drill 6 — List with sections  *(from-scratch)*

Render the `groups` data as a sectioned `List` — section title + items per section.

---

## Drill 7 — `EnvironmentObject` → `@Environment(_)` migration  *(port)*

Old (pre-iOS 17) code uses `@EnvironmentObject` + `ObservableObject`. Migrate to the iOS 17+ `@Observable` + `@Environment(_)` style.
