# ❓ 50 Mock Interview Questions

> ⏱ Train answering each in **under 3 minutes**. Mark ⚠️ ones you stumble on and revisit.

## SwiftUI fundamentals

1. **Difference between `@State`, `@Binding`, `@StateObject`, `@ObservedObject` and `@Environment`?**
   `@State` = local view state; `@Binding` = bidirectional reference to another view's `@State`; `@StateObject` creates and owns once; `@ObservedObject` is passed in; `@Environment` reads from the ambient injection.

2. **What changed with the `@Observable` macro (iOS 17+)?**
   Replaces `ObservableObject` + `@Published`. Per-keypath dependency tracking — a view re-renders only when the specific field it reads changes (fine-grained), reducing wasted invalidations.

3. **How does SwiftUI know when to re-render a view?**
   When a `@State`, `@Binding` or `@Observable` property the view *actually read* changes. SwiftUI then runs `body` again and diffs the resulting tree, applying minimal updates.

4. **`.task {}` vs `Task {}` — which to use?**
   `.task {}` is tied to the view lifecycle (auto-cancels on disappear). `Task {}` is detached — it can leak if not cancelled manually.

5. **What is `body: some View`?**
   An opaque return type — the view knows its concrete type at compile time, but the caller only sees "some View". Enables zero-overhead composition.

6. **What is `@ViewBuilder` for?**
   Lets you use `if`/`switch`/`for` inside view-building closures. Implicit on `body`, explicit when you write your own helper closures.

7. **PreferenceKey vs EnvironmentValues — when to use each?**
   PreferenceKey: child → ancestor (reporting up). Environment: ancestor → descendants (config flowing down).

8. **What is `matchedGeometryEffect`?**
   Animates a view "moving" between two locations in the hierarchy, even across logical boundaries. Used for hero transitions.

9. **`LazyVStack` vs `VStack`?**
   `Lazy*` creates children on demand (visible only). `VStack` always creates all children. Lazy = better perf for large lists.

10. **How do you pass data between screens with `NavigationStack`?**
    `NavigationLink(value:)` + `.navigationDestination(for:)`. For programmatic control, bind a `path` to `NavigationStack(path:)`.

## Concurrency

11. **`async let` vs `TaskGroup` — when to use each?**
    `async let` for a fixed, compile-time-known number of parallel tasks. `TaskGroup` for a dynamic count (loop / data-driven).

12. **What is an `actor`?**
    A reference type with isolated mutable state — only one task accesses members at a time. Eliminates data races by construction.

13. **What's `@MainActor` for?**
    Guarantees the function/type runs on the main thread. Essential for UI updates.

14. **How do you cancel a `Task`?**
    Call `.cancel()` on the handle, or rely on cascade (parent cancellation propagates). Use `try Task.checkCancellation()` or `Task.isCancelled` to bail out cooperatively.

15. **What is `Sendable`?**
    A marker protocol meaning "safe to cross isolation boundaries". The compiler verifies — value types with Sendable members get it for free; classes need to opt in carefully.

16. **`Task.sleep` vs `Thread.sleep`?**
    `Task.sleep` is cooperative — yields the thread, supports cancellation. `Thread.sleep` blocks the entire thread.

17. **What's `AsyncStream` for?**
    Bridges callback-based or timer-based APIs into `AsyncSequence` so consumers can use `for await`.

18. **What is actor reentrancy and why is it tricky?**
    `await` inside an actor releases its lock — other tasks can interleave. State you read before `await` may have changed by the time execution resumes.

19. **How do you migrate `completion: @escaping` to async?**
    `withCheckedContinuation { cont in api { result in cont.resume(returning: result) } }` (or `withCheckedThrowingContinuation` for throwing variants).

20. **Detached vs structured Task — what's the difference?**
    Detached doesn't inherit context (priority, MainActor isolation, cancellation). Use only when you intentionally want to escape the current context.

## UIKit

21. **UIViewController lifecycle, in order:**
    `init` → `loadView` → `viewDidLoad` (once) → `viewWillAppear` → `viewIsAppearing` (iOS 13+) → `viewDidAppear` → ... `viewWillDisappear` → `viewDidDisappear` → `deinit`.

22. **`viewDidLoad` vs `viewWillAppear`?**
    `viewDidLoad` fires once when the view is loaded. `viewWillAppear` fires every time the view appears (e.g., returning from a pushed detail).

23. **Auto Layout: what is "intrinsic content size"?**
    The view's natural size derived from its content (UILabel from text, UIImageView from image). Constraints can rely on this, removing the need to declare every dimension explicitly.

24. **Hugging vs Compression Resistance?**
    Hugging = resistance to growing larger than intrinsic. Compression = resistance to shrinking smaller than intrinsic. Higher priority = stronger resistance.

25. **`frame` vs `bounds`?**
    `frame` is position+size in the superview's coordinate system. `bounds` is the view's own coordinate system (origin usually 0,0).

26. **Why is `UICollectionViewDiffableDataSource` better?**
    Animates diffs automatically; eliminates `performBatchUpdates` boilerplate; prevents the inconsistencies between data and UI that classic delegate-based code is prone to.

27. **Compositional vs Flow Layout?**
    Compositional is declarative, supports heterogeneous sections, orthogonal scrolling, supplementary items. Flow is the legacy linear layout.

28. **What is the responder chain?**
    The chain of objects that respond to events (touch, motion, key, action). It walks view → superview → ... → view controller → window → application.

29. **How do you avoid retain cycles in closures?**
    `[weak self]` (most common) or `[unowned self]` (when self is guaranteed to outlive the closure).

30. **How do you pass data between VCs with Storyboards?**
    Override `prepare(for:sender:)`, check `segue.identifier`, set destination properties. Without storyboards: dependency-inject via init or property.

## SwiftUI ↔ UIKit interop

31. **Required methods for `UIViewRepresentable`?**
    `makeUIView(context:)` to create the UIView; `updateUIView(_:context:)` to sync the UIView with SwiftUI state.

32. **What's the role of the Coordinator?**
    Receives UIKit delegate callbacks (UITextFieldDelegate, MKMapViewDelegate, etc.) and translates them into SwiftUI state updates (Bindings, closures).

33. **How do you embed SwiftUI inside UIKit?**
    `UIHostingController(rootView: MyView())`. Add as a child VC, pin its view's edges with constraints.

34. **Can you pass a `@Binding` into a `UIViewRepresentable`?**
    Yes — that's the standard way to enable two-way communication. The Coordinator updates the binding from delegate callbacks.

## Architecture & best practices

35. **MVVM vs MVC in iOS?**
    MVC tends to bloat the VC ("Massive View Controller"). MVVM extracts presentation logic into a testable ViewModel.

36. **Why dependency injection?**
    Testability (mock IO), reuse, low coupling — and explicit boundaries that make code easier to reason about.

37. **Singletons — yes or no?**
    Only for genuinely global services (`URLSession.shared`, etc.). Otherwise inject — singletons hide dependencies and break testability.

38. **How do you organize modules in a large app?**
    By feature (vertical slices), each as a local SPM package containing View, ViewModel, Repository, and models. Cross-feature contracts go in shared lightweight packages.

39. **What is "Massive View Controller" and how do you avoid it?**
    A VC carrying too much logic. Avoid by extracting ViewModel (presentation), Coordinator (navigation), Service (IO), and DataSource (table/collection plumbing).

40. **When to use Combine vs async/await in 2026?**
    async/await for one-shot flows (fetch, decode, write). Combine for continuous streams (search debounce, observers, multi-publisher composition).

## Performance & memory

41. **How do you detect memory leaks?**
    Instruments → Leaks; the Memory Graph debugger in Xcode; setting breakpoints in `deinit` to verify it's called.

42. **How do you optimize a slow `List`?**
    Stable `.id(...)`; switch to `LazyVStack` if needed; avoid heavy work in `body`; use `@Observable` (fine-grained re-renders); precompute derived values.

43. **`drawRect` vs `CALayer` for performance?**
    `CALayer` is GPU-accelerated and composited. `drawRect` runs on the CPU. Prefer layers / SwiftUI shapes.

44. **`weak` vs `unowned`?**
    `weak` becomes `nil` when the referent deallocs (Optional). `unowned` is non-Optional and crashes on use-after-free.

45. **What is copy-on-write (COW)?**
    Value types like `Array` and `Dictionary` share their underlying storage until a mutation occurs — only then is a copy made. Cheap to pass around.

## Testing & debugging

46. **How do you test an async ViewModel?**
    `func test_x() async { await sut.load(); XCTAssertEqual(sut.state, .loaded(...)) }`. No expectations needed for await-driven flows.

47. **When are snapshot tests worth it?**
    For visual regression on stable components with many states (design system). They're expensive to maintain — use selectively.

48. **How do you debug excessive SwiftUI re-renders?**
    `Self._printChanges()` inside `body`; Instruments → SwiftUI; check what state your view is reading and whether it should be split.

49. **`XCTestExpectation` vs async tests?**
    Expectations are the older callback-based style. Async tests are direct and more readable — prefer them for new code.

50. **How do you handle flaky tests?**
    Identify the source (timing, ordering, real IO). Make the test deterministic (mock clock, mock network, controlled scheduler). Never paper over with `sleep`.

---

> 🎯 **Interview tip**: when you don't know, say "I'm not certain, but I'd guess..." — a senior engineer reasoning out loud beats one bluffing.
