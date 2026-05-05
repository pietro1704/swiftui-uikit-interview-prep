# 02 — SwiftUI Intermediate

Once Page 01 is comfortable, these are the second-round drills: environment-based DI, identity tricks, view modifiers, preference keys, navigation as data, custom Layout, focus.

> Open side-by-side with `Playground/Livecoding.playground/Pages/02_SwiftUI_Intermediate.xcplaygroundpage/Contents.swift`.

---

## Drill 1 — Inject a dependency without prop-drilling  *(from-scratch)*

You have an `APIClient` protocol used by 5 nested views. The interviewer says: "I don't want a singleton, and I don't want to thread the client through every initializer. How would you do it in SwiftUI?"

**Talk-track**: "SwiftUI's Environment is the canonical answer: define an EnvironmentKey with a default, expose a property on EnvironmentValues, inject at the top with `.environment(\.apiClient, ...)`, read deep with `@Environment`. Tests/previews override per-call site."

---

## Drill 2 — View identity surprise  *(bug-hunt)*

The detail screen in the Swift file loses its scroll position whenever the user picks a different item from a menu. Why, and what's the one-liner fix?

---

## Drill 3 — Reusable modifier with parameters  *(from-scratch)*

Build a modifier `roundedShadow(radius:corner:)` so any view can call `.roundedShadow(radius: 8, corner: 12)` like a built-in. Show:

- the `ViewModifier` struct
- the `View` extension that makes it ergonomic.

---

## Drill 4 — `PreferenceKey` — child reports up  *(from-scratch)*

Read the on-screen height of a child view back to the parent so the parent can size a sibling to match.

**Talk-track**: "Environment goes parent→child. PreferenceKey goes child→parent. The child writes via `.preference(key:value:)`, the ancestor reads via `.onPreferenceChange(...)`."

---

## Drill 5 — Data-driven navigation in MVVM  *(from-scratch)*

The interviewer asks: "In MVVM SwiftUI, where does navigation live?" Build a list view + detail view where tapping a row pushes the detail. Navigation state lives in the view-model, not in `@State` on the View.

---

## Drill 6 — Custom Layout — wrapping tag cloud  *(from-scratch)*

Build a `TagCloudLayout: Layout` that wraps tags onto multiple rows when they don't fit horizontally.

**Talk-track**: "The Layout protocol gives you `sizeThatFits` and `placeSubviews`. I receive a proposed size from the parent, walk subviews measuring each, advance an x-cursor, wrap to next row when overflowing."

---

## Drill 7 — Focus & keyboard with `@FocusState`  *(from-scratch)*

LoginForm has username + password fields. On appear, focus the username. On submit, move focus to password; if password submit, dismiss focus.

---

## Drill 8 — `NavigationStack(path:)` — deep link  *(bug-hunt)*

The deep-link silently does nothing. Why?

---

## Drill 9 — `AnyLayout` — adapt HStack/VStack  *(from-scratch)*

Build a screen whose layout is `HStack` on regular size class and `VStack` on compact, switching dynamically when the size class changes — preserving subview identity.
