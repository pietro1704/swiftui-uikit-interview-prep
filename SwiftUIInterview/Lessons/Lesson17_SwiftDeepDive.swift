import SwiftUI

// MARK: - Lesson 17 — Swift language deep dive
//
// The four things interviewers love to grill on:
//  1. Generics + protocols with associated types (PAT)
//  2. Opaque return types (`some`) vs existentials (`any`)
//  3. Result builders (how SwiftUI's @ViewBuilder works under the hood)
//  4. Property wrappers (build a tiny @Clamped from scratch)

// =====================================================================
// MARK: 1) Generics + PAT + `some`/`any`
// =====================================================================

protocol DataSource {
    associatedtype Item
    func load() async throws -> [Item]
}

struct LocalUsers: DataSource {
    func load() async throws -> [String] { ["Ana", "Beto", "Caio"] }
}

struct RemoteFlags: DataSource {
    func load() async throws -> [Bool] { [true, false, true] }
}

// `some DataSource` — opaque: caller knows the concrete type at compile time, hidden from the API
func makeUsersSource() -> some DataSource { LocalUsers() }

// `any DataSource` — existential: erased; caller treats it as a box at runtime
func anyDataSource(remote: Bool) -> any DataSource {
    remote ? AnyDataSource(RemoteFlags()) : AnyDataSource(LocalUsers())
}

// Trivial wrapper since DataSource has a PAT and can't be returned heterogeneously.
struct AnyDataSource<D: DataSource>: DataSource {
    private let _load: () async throws -> [D.Item]
    init(_ wrapped: D) { self._load = wrapped.load }
    func load() async throws -> [D.Item] { try await _load() }
}

// =====================================================================
// MARK: 2) Result builder (mini @ViewBuilder)
// =====================================================================

@resultBuilder
enum StringListBuilder {
    static func buildBlock(_ parts: [String]...) -> [String] { parts.flatMap { $0 } }
    static func buildExpression(_ str: String) -> [String] { [str] }
    static func buildExpression(_ arr: [String]) -> [String] { arr }
    static func buildOptional(_ part: [String]?) -> [String] { part ?? [] }
    static func buildEither(first: [String]) -> [String] { first }
    static func buildEither(second: [String]) -> [String] { second }
    static func buildArray(_ parts: [[String]]) -> [String] { parts.flatMap { $0 } }
}

func bulletedList(@StringListBuilder _ build: () -> [String]) -> String {
    build().map { "• \($0)" }.joined(separator: "\n")
}

// =====================================================================
// MARK: 3) Custom property wrapper
// =====================================================================

@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
}

struct Player {
    @Clamped(0...100) var hp: Int = 50
}

// =====================================================================
// MARK: View
// =====================================================================

struct Lesson17View: View {
    @State private var hpDemo: String = ""
    @State private var listDemo: String = ""
    @State private var includeUppercase = true

    var body: some View {
        LessonScaffold(
            title: "17 — Swift deep dive",
            goal: "Generics + PAT, `some` vs `any`, result builders, custom property wrappers.",
            exercise: """
            1. Build a `@Capitalized` property wrapper that lowercases input then capitalizes the first letter.
            2. Convert `bulletedList` so the `if`/`else` paths render different bullets.
            3. Bonus: write a generic `Cache<Key: Hashable, Value>` actor with TTL eviction.
            """
        ) {
            GroupBox("Custom @Clamped wrapper") {
                Button("Push hp = 200 (clamped to 100)") {
                    var p = Player()
                    p.hp = 200
                    hpDemo = "hp after assigning 200 → \(p.hp)"
                }
                Text(hpDemo).font(.callout.monospaced())
            }

            GroupBox("Custom result builder") {
                Toggle("Include uppercase line", isOn: $includeUppercase)
                Button("Build list") {
                    listDemo = bulletedList {
                        "Generics"
                        "Opaque types"
                        if includeUppercase {
                            "RESULT BUILDERS"
                        } else {
                            "Result builders"
                        }
                        "Property wrappers"
                    }
                }
                if !listDemo.isEmpty {
                    Text(listDemo).font(.callout.monospaced())
                }
            }

            GroupBox("`some` vs `any`") {
                Text("""
                some DataSource → opaque, single concrete type, zero overhead.
                any DataSource  → existential box, lets you pick the type at runtime.
                Use `some` when you can; `any` only when you really need heterogeneity.
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview { NavigationStack { Lesson17View() } }
