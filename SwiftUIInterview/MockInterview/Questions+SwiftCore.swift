import Foundation

// 15 Swift deep-dive questions covering: opaque/existential types, ARC,
// generics, property wrappers, result builders, KeyPath, conditional
// conformance, dynamicMemberLookup, macros, AnyHashable.

extension QuestionBank {
    static let swiftCore: [Question] = [
        Question(
            id: 16,
            topic: .swiftCore,
            prompt: """
            Pick the right return-type for `func makeView() -> ???` representing \
            "any View". When do you choose `some View` vs `any View`?
            """,
            options: [
                "Always `any View`. `some View` is legacy.",
                "Always `some View`. `any View` doesn't compile.",
                "`some View` (opaque) when the *concrete* type is fixed but private — cheap, statically-dispatched. `any View` (existential) only when the concrete type genuinely varies at runtime — boxes, more expensive.",
                "They're identical performance-wise."
            ],
            correctIndex: 2,
            explanation: """
            `some` is opaque: caller can't see the type but the compiler still \
            knows it. `any` is an existential box that erases the type at \
            runtime — necessary for heterogeneous collections (`var renderers: \
            [any Renderer]`), but adds indirection. In SwiftUI, almost always \
            reach for `some View`.
            """,
            starterCode: """
            func a() -> ??? { Text("hi") }
            func b(...) -> ??? { Bool.random() ? Text("a") : Image(systemName: "x") }
            """,
            referenceSolution: """
            func a() -> some View { Text("hi") }

            @ViewBuilder
            func b(_ flag: Bool) -> some View {
                if flag { Text("a") } else { Image(systemName: "x") }
            }
            // @ViewBuilder yields _ConditionalContent — still some View, no AnyView.
            """
        ),
        Question(
            id: 17,
            topic: .swiftCore,
            prompt: """
            Inside a Combine `sink`, you write `self.value = newValue`. ARC: \
            does this leak, and why does the textbook fix specify `[weak self]` \
            but NOT `[unowned self]`?
            """,
            options: [
                "Doesn't leak — Combine breaks reference cycles automatically.",
                "Leaks because the closure captures self strongly, the AnyCancellable is owned by self, and the publisher chain holds the closure → cycle. Use `[weak self]`; `unowned` would crash if self deallocates before the publisher completes.",
                "Use `[unowned self]` — it's faster and never crashes.",
                "Marking value as `@Published` removes the cycle."
            ],
            correctIndex: 1,
            explanation: """
            Cycle: publisher → closure → self → AnyCancellable → publisher. \
            `[weak self]` breaks the closure→self edge. `[unowned self]` \
            assumes self outlives the closure — but publishers can emit after \
            view dismiss, exactly violating that assumption.
            """,
            starterCode: """
            final class VM {
                @Published var query = ""
                var bag = Set<AnyCancellable>()
                var value = ""
                func bind() {
                    $query.sink { newValue in
                        self.value = newValue   // STRONG self captured
                    }.store(in: &bag)
                }
            }
            """,
            referenceSolution: """
            final class VM {
                @Published var query = ""
                var bag = Set<AnyCancellable>()
                var value = ""
                func bind() {
                    $query.sink { [weak self] newValue in
                        self?.value = newValue
                    }.store(in: &bag)
                }
            }
            // Or: $query.assign(to: &$value)  — Combine's built-in cycle-safe assignment.
            """
        ),
        Question(
            id: 18,
            topic: .swiftCore,
            prompt: """
            A `struct Document { var pages: [Page] }` is passed by value all over. \
            Why isn't this catastrophic for memory, and what would force a copy?
            """,
            options: [
                "Swift secretly converts large structs to classes.",
                "`Array` and most stdlib collections are copy-on-write: assignments share storage by reference until *one side mutates*, only then a deep copy occurs.",
                "Structs are always lightweight; size doesn't matter.",
                "It IS catastrophic — always wrap large structs in a class."
            ],
            correctIndex: 1,
            explanation: """
            CoW is implemented in Array, Dictionary, Set, String. Assignment \
            is O(1); a write triggers `_makeUniqueAndReserveCapacityIfNotUnique`, \
            cloning only if shared. Custom value types can opt in via \
            `isKnownUniquelyReferenced`.
            """,
            starterCode: """
            // Build a custom CoW wrapper around class-backed buffer.
            struct Buffer { /* class-backed storage with value semantics */ }
            """,
            referenceSolution: """
            final class Storage {
                var data: [Int]
                init(_ d: [Int]) { self.data = d }
                func clone() -> Storage { Storage(data) }
            }
            struct Buffer {
                private var storage: Storage
                init(_ data: [Int] = []) { self.storage = Storage(data) }
                var data: [Int] { storage.data }
                mutating func append(_ x: Int) {
                    if !isKnownUniquelyReferenced(&storage) {
                        storage = storage.clone()
                    }
                    storage.data.append(x)
                }
            }
            """
        ),
        Question(
            id: 19,
            topic: .swiftCore,
            prompt: """
            Generics with constraints vs `[any Equatable]`: when does \
            `func process<T: Equatable>(_ items: [T])` beat the existential?
            """,
            options: [
                "They're identical.",
                "The generic version preserves T's identity across the function — you can compare two T's, return T, store T homogeneously. The existential `[any Equatable]` erases per-element type, so two elements aren't necessarily comparable to each other. Generics also enable static dispatch.",
                "The existential is always faster.",
                "Generics can't hold collections."
            ],
            correctIndex: 1,
            explanation: """
            `[any Equatable]` is heterogeneous — element 0 might be Int, \
            element 1 String; `items[0] == items[1]` doesn't typecheck. Generic \
            T constrains all elements to one type. Plus static dispatch: no \
            existential box, often inlinable.
            """,
            starterCode: """
            // Function: return first duplicate in an array.
            func firstDuplicate(...) -> ???
            """,
            referenceSolution: """
            func firstDuplicate<T: Hashable>(_ items: [T]) -> T? {
                var seen = Set<T>()
                for item in items {
                    if !seen.insert(item).inserted { return item }
                }
                return nil
            }
            // [any Hashable] would NOT let us put items in Set<T> — Set needs
            // a single Hashable type T at the type level.
            """
        ),
        Question(
            id: 20,
            topic: .swiftCore,
            prompt: """
            Why doesn't `@Published var x = 0` work in a struct, and what's \
            the deeper constraint property wrappers and result builders share?
            """,
            options: [
                "Compiler bug.",
                "`@Published` synthesizes a `projectedValue` that needs reference-type backing storage; structs have value semantics. Both result builders and property wrappers are *compile-time* desugaring tools — but @Published specifically requires a class because its publisher captures self.",
                "Structs cannot have any property wrappers.",
                "@Published requires @MainActor."
            ],
            correctIndex: 1,
            explanation: """
            "@Published is only available on properties of classes" — the \
            synthesized publisher needs identity (outlives setter calls, emits \
            over time), demanding a reference. Insight: both `@propertyWrapper` \
            and `@resultBuilder` are *compile-time* macros desugaring into \
            ordinary types — not runtime magic.
            """,
            starterCode: """
            struct Counter {
                @Published var count = 0   // ❌ won't compile
            }
            """,
            referenceSolution: """
            // (1) Use a class:
            final class Counter: ObservableObject {
                @Published var count = 0
            }
            // (2) Or migrate to @Observable (modern):
            @Observable final class Counter { var count = 0 }

            // What @Published desugars to:
            //   private var _count: Published<Int> = Published(initialValue: 0)
            //   var count: Int { get { _count.value } set { _count.value = newValue } }
            //   var $count: Publisher<Int, Never> { _count.projectedValue }
            // The Published<Int> holds a CurrentValueSubject — a class — so
            // the enclosing type must also be a class.
            """
        ),

        // ==============================================================
        // NEW QUESTIONS — Q51–60
        // ==============================================================

        Question(
            id: 51,
            topic: .swiftCore,
            prompt: """
            What's the difference between `KeyPath`, `WritableKeyPath`, and \
            `ReferenceWritableKeyPath`?
            """,
            options: [
                "All the same; named for documentation.",
                "`KeyPath<Root, Value>` reads only. `WritableKeyPath<Root, Value>` reads and writes (root must be `inout` or a value-type variable). `ReferenceWritableKeyPath<Root, Value>` writes through a class instance — the root is a reference, so you can write through a `let` constant of the class.",
                "WritableKeyPath only works on actors.",
                "Reference-writable is for global vars only."
            ],
            correctIndex: 1,
            explanation: """
            KeyPaths form a hierarchy. `KeyPath` is read-only. `WritableKeyPath` \
            adds write capability for value semantics — needs an `inout`/`var` \
            container. `ReferenceWritableKeyPath` writes through a class \
            instance — works on `let` because mutating the *referent*, not \
            the reference. SwiftUI's Bindings rely on these distinctions.
            """,
            starterCode: """
            // Show one of each and a function that takes them.
            """,
            referenceSolution: """
            struct Person { var name: String }       // value type
            final class Account { var balance: Int = 0 } // class

            let nameKey: WritableKeyPath<Person, String> = \\.name        // value-type write
            let balanceKey: ReferenceWritableKeyPath<Account, Int> = \\.balance

            var p = Person(name: "Ana")
            p[keyPath: nameKey] = "Bia"   // OK: var p

            let acc = Account()
            acc[keyPath: balanceKey] = 100  // OK even though acc is `let` — class write

            // Generic helper that ONLY works for class roots:
            func bump<R: AnyObject>(_ root: R, _ kp: ReferenceWritableKeyPath<R, Int>) {
                root[keyPath: kp] += 1
            }
            """
        ),
        Question(
            id: 52,
            topic: .swiftCore,
            prompt: """
            Conditional conformance: what does this enable, and why is it \
            powerful?
            ```swift
            extension Array: Equatable where Element: Equatable { ... }
            ```
            """,
            options: [
                "It overloads ==.",
                "It says 'Array is Equatable WHEN its Element is'. The compiler synthesizes the correct conformance for any Element type that meets the constraint, without needing a separate type. This is how stdlib expresses 'Array<Int> is Equatable but Array<UIView> isn't' — a single type with conformance dependent on its generic parameters.",
                "It's a deprecated form of dynamic dispatch.",
                "It only works on tuples."
            ],
            correctIndex: 1,
            explanation: """
            Conditional conformance lets a generic type conform to a protocol \
            *only when* its type parameters meet certain constraints. The \
            compiler picks the right witness table at the call site. \
            `Array<T>: Equatable where T: Equatable` is THE canonical example \
            — same struct, different conformance based on T.
            """,
            starterCode: """
            // Make a Box<T> Hashable WHEN T is Hashable.
            struct Box<T> { let value: T }
            """,
            referenceSolution: """
            struct Box<T> { let value: T }
            extension Box: Equatable where T: Equatable {
                static func == (lhs: Box<T>, rhs: Box<T>) -> Bool { lhs.value == rhs.value }
            }
            extension Box: Hashable where T: Hashable {
                func hash(into hasher: inout Hasher) { hasher.combine(value) }
            }
            // Box<Int> can go in a Set; Box<UIView> can't — same type, different
            // conformance based on T.
            """
        ),
        Question(
            id: 53,
            topic: .swiftCore,
            prompt: """
            What does `where Self: SomeProtocol` do in a protocol extension, \
            and when is it the right tool?
            """,
            options: [
                "It restricts the protocol's conformers.",
                "Inside `extension SomeProtocol where Self: AnotherProtocol { ... }`, the methods are only available when the conformer ALSO conforms to AnotherProtocol. It's how stdlib gives you, e.g., `Sequence` operations only when `Element: Hashable`. Useful for adding capability that depends on additional constraints.",
                "It's how you make a protocol final.",
                "It's a deprecated alias for associatedtype."
            ],
            correctIndex: 1,
            explanation: """
            Protocol extensions with `where` constraints add functionality \
            *conditionally*. The methods exist only when the conformer also \
            satisfies the where clause. Used everywhere in stdlib: \
            `extension Sequence where Element: Hashable { func unique() }`. \
            Lets you build expressive, optional capabilities.
            """,
            starterCode: """
            // Add `func sum() -> Element` to Sequence WHERE Element: Numeric.
            """,
            referenceSolution: """
            extension Sequence where Element: Numeric {
                func sum() -> Element {
                    reduce(.zero, +)
                }
            }
            // Now [1, 2, 3].sum() works.
            // [\"a\", \"b\"].sum() doesn't compile (String isn't Numeric).
            """
        ),
        Question(
            id: 54,
            topic: .swiftCore,
            prompt: """
            What does `@dynamicMemberLookup` do, and where is it idiomatic to \
            use it?
            """,
            options: [
                "It enables runtime stringly-typed access — bad practice.",
                "It lets you intercept `instance.foo` member accesses through `subscript(dynamicMember:)`. Idiomatic uses: typed wrappers around dynamic data (JSON proxies, Bindable property forwarding in SwiftUI), key-path forwarding (`@dynamicMemberLookup<Wrapped, T>` forwards `wrapper.x` to `wrapped[keyPath: \\.x]`).",
                "It's how you access private properties.",
                "It's deprecated in Swift 6."
            ],
            correctIndex: 1,
            explanation: """
            `@dynamicMemberLookup` is what makes SwiftUI's Bindings ergonomic: \
            `$user.name` works because `Bindable` uses dynamicMemberLookup with \
            keypath forwarding. Also used by Apollo (GraphQL), JSON wrappers, \
            and "view model proxies" that forward properties to underlying \
            data. Type-safe with KeyPaths; unsafe with String.
            """,
            starterCode: """
            // Build a Box<T> with @dynamicMemberLookup that forwards properties of T.
            """,
            referenceSolution: """
            @dynamicMemberLookup
            struct Box<T> {
                var wrapped: T
                subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U {
                    wrapped[keyPath: keyPath]
                }
            }
            struct User { let name: String; let age: Int }
            let box = Box(wrapped: User(name: "Ana", age: 30))
            print(box.name)  // "Ana" — forwarded via dynamicMemberLookup
            print(box.age)   // 30
            // Compile-time safe: box.foo doesn't compile (no KeyPath<User, _> for foo).
            """
        ),
        Question(
            id: 55,
            topic: .swiftCore,
            prompt: """
            Swift macros (Swift 5.9+): what's the difference between a \
            *freestanding* macro (e.g., `#Preview { ... }`) and an *attached* \
            macro (e.g., `@Observable`)?
            """,
            options: [
                "They're the same; different syntax for the same thing.",
                "Freestanding macros (`#name(...)`) expand at the expression or declaration position; they REPLACE themselves with the generated code. Attached macros (`@Name`) decorate an existing declaration (type/function/property) and ADD members or modify it in place. `@Observable` adds @Published-equivalent storage and Observation conformance to a class.",
                "Freestanding only works on iOS; attached works everywhere.",
                "Attached macros are obsoleted by Swift 6."
            ],
            correctIndex: 1,
            explanation: """
            Freestanding (`#`): replaces a position with code. Examples: \
            `#Preview { ... }` produces a Preview type; `#warning("...")` emits \
            a compiler warning. Attached (`@`): augments a declaration. \
            Examples: `@Observable` synthesizes Observation registrar + \
            tracking; `@AddCompletionHandler` generates async-to-callback \
            shims. You can write your own with `SwiftSyntax`.
            """,
            starterCode: """
            // No code — verbal/conceptual answer + concrete examples.
            """,
            referenceSolution: """
            // FREESTANDING — replaces position:
            #Preview { ContentView() }   // → expands to a _PreviewType...
            #warning("TODO")              // → compiler warning at this point

            // ATTACHED — decorates declaration:
            @Observable
            final class VM {
                var count = 0
            }
            // → expands to add Observable conformance, internal _$observationRegistrar,
            //   and rewrites stored properties to track access via the registrar.

            // Other attached macros:
            //  @Entry on EnvironmentValues property → synthesizes EnvironmentKey
            //  @State, @Binding etc. are NOT macros (they're property wrappers
            //  predating macros), but conceptually attached.
            """
        ),
        Question(
            id: 56,
            topic: .swiftCore,
            prompt: """
            Property wrappers that compose: `@MainActor @Published var x = 0` \
            in a class. Order of `@`s — does it matter?
            """,
            options: [
                "No, order is arbitrary.",
                "Yes — property wrappers are NESTED in declaration order. `@A @B var x` desugars to `A<B<Type>>`. With `@Published @SomeWrapper var x`, the projectedValue ($x) belongs to the OUTERMOST wrapper. Plus, `@MainActor` is an actor isolation marker, not a property wrapper — but its position relative to `@Published` matters for compile-time isolation rules.",
                "Property wrappers can't compose — pick one.",
                "Order matters only for SwiftUI views."
            ],
            correctIndex: 1,
            explanation: """
            Property wrappers nest: `@A @B var x: T` → underlying storage is \
            `A<B<T>>`. The OUTER wrapper's projectedValue is what `$x` exposes. \
            For `@Published`, this means the position of `@Published` decides \
            whether `$x` is a publisher or whatever the other wrapper exposes. \
            `@MainActor` isn't a property wrapper but an isolation attribute — \
            doesn't compose the same way, but DOES interact with property \
            wrappers' init/access patterns.
            """,
            starterCode: """
            // No code — verbal answer + a small experiment in a Playground.
            """,
            referenceSolution: """
            // Mental model:
            //   @Published @SomeWrapper var x: Int = 0
            // becomes (sketch):
            //   private var _x = Published<SomeWrapper<Int>>(initialValue: ...)
            //   var x: Int { get { _x.value.wrappedValue } set { ... } }
            //   var $x: Publisher<...> { _x.projectedValue }
            //
            // The OUTER wrapper (Published) provides $x. If you flip:
            //   @SomeWrapper @Published var x
            // Now SomeWrapper is outer; $x is whatever SomeWrapper projects.
            //
            // Practical advice: only compose when you understand both wrappers'
            // init signatures (each has its own init(wrappedValue:)). When
            // it's painful, refactor — most apps don't need composed wrappers.
            """
        ),
        Question(
            id: 57,
            topic: .swiftCore,
            prompt: """
            `AnyHashable` performance — when does using `[AnyHashable: Any]` \
            instead of a typed dict bite you?
            """,
            options: [
                "Never — same performance.",
                "AnyHashable boxes the underlying type at runtime. Hashing costs an extra pointer indirection per lookup; equality goes through dynamic dispatch. For hot paths (large dicts, frequent lookups), it can be 2-5x slower than a typed Dictionary<Int, Foo>. Plus you lose compile-time type safety on values.",
                "AnyHashable is faster because it's optimized.",
                "Only an issue on iOS; macOS handles it natively."
            ],
            correctIndex: 1,
            explanation: """
            AnyHashable wraps any Hashable in an existential box. Hash and == \
            are forwarded through dynamic dispatch and box-unwrap. For most \
            apps imperceptible; for tight loops over large dicts (CoreData \
            faulting, heavy maps) it shows up in Instruments. NSDictionary \
            bridging often pays this cost. If perf-critical, type the dict.
            """,
            starterCode: """
            // No code — discuss + show benchmark sketch.
            """,
            referenceSolution: """
            // Faster:
            var users: [UUID: User] = [:]    // typed; hash uses UUID.hashValue directly

            // Slower in hot paths:
            var props: [AnyHashable: Any] = [:]   // forwarded hash + dynamic ==

            // Senior intuition: reach for typed when keys are known; AnyHashable
            // is for genuinely heterogeneous keying (analytics events with
            // mixed key types) — and then accept the cost.
            //
            // NSCache, Notification.userInfo, Combine subjects often pay this
            // because Apple SDKs predate generics in those positions.
            """
        ),
        Question(
            id: 58,
            topic: .swiftCore,
            prompt: """
            What's `ObjectIdentifier` for, and how does it differ from `===`?
            """,
            options: [
                "Same thing; pick by taste.",
                "`ObjectIdentifier(obj)` extracts a `Hashable` token uniquely identifying a class instance — useful as a Dictionary key or Set member. `===` is a binary operator returning Bool. ObjectIdentifier wraps the same identity into a Hashable value type.",
                "ObjectIdentifier is for protocol identity; === is for class identity.",
                "ObjectIdentifier doesn't exist."
            ],
            correctIndex: 1,
            explanation: """
            `===` answers "are these two references the same instance?" — Bool. \
            `ObjectIdentifier(x) == ObjectIdentifier(y)` is the same check. \
            But ObjectIdentifier is also Hashable, so you can use it as a dict \
            key: `[ObjectIdentifier: Subscriber]`. Combine and Observation \
            internally use this for tracking subscribers without retaining them.
            """,
            starterCode: """
            // Build a registry that keys subscribers by their object identity.
            """,
            referenceSolution: """
            final class WeakBox<T: AnyObject> {
                weak var value: T?
                init(_ v: T) { self.value = v }
            }
            final class Registry<T: AnyObject> {
                private var entries: [ObjectIdentifier: WeakBox<T>] = [:]
                func add(_ object: T) {
                    entries[ObjectIdentifier(object)] = WeakBox(object)
                }
                func remove(_ object: T) {
                    entries[ObjectIdentifier(object)] = nil
                }
                var live: [T] {
                    entries.values.compactMap { $0.value }
                }
            }
            // Combine's Subjects keep subscribers in a similar map.
            """
        ),
        Question(
            id: 59,
            topic: .swiftCore,
            prompt: """
            `@inlinable`, `@usableFromInline`, `@_specialize` — when do they \
            actually matter?
            """,
            options: [
                "They're internal compiler details, never used by app developers.",
                "They matter for SPM library authors who need cross-module optimization. `@inlinable` exposes the function body to clients so the optimizer can inline across module boundaries; otherwise, only the public signature is available. `@usableFromInline` lets you call internal symbols from inlinable code. `@_specialize` is underscored (private API) but generates concrete instantiations for specific generic parameters. App-only code rarely needs these.",
                "Required for all classes in Swift 6.",
                "Improves runtime startup by 50%."
            ],
            correctIndex: 1,
            explanation: """
            These attributes are about cross-module visibility and \
            optimization. By default, function bodies in module A aren't \
            visible to module B, so generic specialization can't happen at \
            B's call site. `@inlinable` exposes the body. `@_specialize` is \
            underscored for a reason — SPI, may break. App devs almost \
            never need these; library authors of perf-critical generic code \
            (e.g., Apple's stdlib team) use them constantly.
            """,
            starterCode: """
            // No code — discuss + show one inlinable function from stdlib.
            """,
            referenceSolution: """
            // Library boundary perf trap (without @inlinable):
            //
            //   public extension Array {
            //       func myMap<T>(_ f: (Element) -> T) -> [T] { ... }
            //   }
            //
            // From a CLIENT module, the optimizer can't specialize myMap to,
            // say, [Int].myMap, because the body isn't visible. You pay the
            // generic indirection cost.
            //
            // Add @inlinable:
            //
            //   @inlinable
            //   public func myMap<T>(_ f: (Element) -> T) -> [T] { ... }
            //
            // Now the body is shipped in the module interface; client modules
            // can specialize. Cost: API stability — body is part of the
            // contract; you can't change it freely.
            //
            // For app code (single module), these don't apply. For SPM
            // libraries, especially perf-critical ones, they're essential.
            """
        ),
        Question(
            id: 60,
            topic: .swiftCore,
            prompt: """
            `Result<Success, Failure>` vs `throws` for error handling. When \
            do you reach for each, and is `Result` "obsolete" in Swift Concurrency?
            """,
            options: [
                "Result is obsolete; always use throws now.",
                "`throws` is the default for synchronous AND async code in modern Swift — cleaner syntax, integrates with structured concurrency. `Result` shines when you need to STORE or PASS errors as values: e.g., `Publisher<Output, Error>`, multiple errors aggregated, retry logic that inspects past failures, message-based architectures (TCA Effects). Use throws by default; use Result when an error needs to live as data.",
                "Result is faster.",
                "throws and Result are interchangeable; pick by mood."
            ],
            correctIndex: 1,
            explanation: """
            Throwing functions return `T` and have an implicit error channel; \
            callers handle with `do/catch`. Cleaner for normal control flow. \
            `Result<Success, Failure>` makes the error a first-class value — \
            you can store it in a property, pass through async boundaries, \
            aggregate (`[Result<...>]`), pattern-match exhaustively. Combine \
            uses Result-shaped types (Publisher's Failure). Both useful; \
            throws is the default in modern code, Result for value-y errors.
            """,
            starterCode: """
            // No code — discuss + sketch when each is right.
            """,
            referenceSolution: """
            // throws (default for control flow):
            func fetchUser(id: UUID) async throws -> User { /* ... */ }
            // caller:
            do { let u = try await fetchUser(id: id) } catch { handle(error) }

            // Result (when error must live as data):
            struct LoadState {
                var lastResult: Result<[Post], Error>?   // remember last outcome
            }
            // Or Combine:
            //   func fetch() -> AnyPublisher<[Post], Error> { ... }
            // (Publisher's Output/Failure is essentially Result on a stream.)

            // Or TCA Effect Result:
            enum Action {
                case dataLoaded(Result<[Post], Error>)   // success/failure as Action
            }
            // The reducer pattern-matches both branches exhaustively.
            """
        )
    ]
}
