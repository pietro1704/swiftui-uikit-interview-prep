import Foundation

// Models a single technical interview question for the senior mock interview.
// Each question has a single correct option, an explanation, an optional
// starter snippet shown read-only in the app, and a reference solution.
// The livecoding actually happens in Playground/Livecoding.playground —
// the app cross-references the relevant page+drill via `livecodingRef`.

enum QuestionTopic: String, CaseIterable, Identifiable, Hashable {
    case concurrency  = "Concurrency"
    case swiftUI      = "Advanced SwiftUI"
    case architecture = "Architecture"
    case swiftCore    = "Swift deep dive"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .concurrency:  "cpu"
        case .swiftUI:      "rectangle.stack.badge.plus"
        case .architecture: "square.3.layers.3d"
        case .swiftCore:    "swift"
        }
    }
}

struct Question: Identifiable, Hashable {
    let id: Int
    let topic: QuestionTopic
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let starterCode: String
    let referenceSolution: String

    /// Cross-reference into Playground/Livecoding.playground.
    /// Hand-picked rather than auto-generated so the mapping is honest:
    /// some questions are conceptual and don't map to a livecoding drill.
    var livecodingRef: String? { Self.livecodingRefs[id] }

    private static let livecodingRefs: [Int: String] = [
        // Concurrency (1–5 original, 21–30 added) → Page 03_AsyncAwait
        1: "03_AsyncAwait · Drill 1 (where Task runs)",
        2: "03_AsyncAwait · Drill 2 (actor reentrancy)",
        3: "03_AsyncAwait · Drill 3 (bounded TaskGroup)",
        4: "03_AsyncAwait · Drill 4 (Sendable migration)",
        5: "03_AsyncAwait · Drill 5 (AsyncStream cleanup)",
        21: "03_AsyncAwait · Drill 6 (GlobalActor)",
        22: "03_AsyncAwait · Drill 7 (isolated parameters)",
        23: "03_AsyncAwait · Drill 8 (Task priority inheritance)",
        24: "03_AsyncAwait · Drill 9 (AsyncSequence vs Combine)",
        25: "03_AsyncAwait · Drill 10 (cancellation propagation)",
        26: "03_AsyncAwait · Drill 11 (async let lifetime)",
        // 27 conceptual: deadlock cooperativo — verbal only
        // 28 conceptual: throwing async stream — verbal
        29: "03_AsyncAwait · Drill 12 (MainActor in init)",
        30: "03_AsyncAwait · Drill 11 (async let lifetime)",

        // SwiftUI (6–10 original, 31–40 added) → Pages 01 & 02
        6: "01_SwiftUI_Fundamentals · Drill 3 (UIKit→SwiftUI port)",
        7: "02_SwiftUI_Intermediate · Drill 4 (PreferenceKey)",
        8: "01_SwiftUI_Fundamentals · Drill 2 (identity bug)",
        9: "02_SwiftUI_Intermediate · Drill 3 (custom modifier)",
        // 10 conceptual: matchedGeometryEffect — discussed
        31: "02_SwiftUI_Intermediate · Drill 6 (custom Layout)",
        32: "01_SwiftUI_Fundamentals · Drill 4 (.task vs .onAppear)",
        33: "02_SwiftUI_Intermediate · Drill 7 (focus & keyboard)",
        34: "01_SwiftUI_Fundamentals · Drill 5 (@Bindable)",
        35: "02_SwiftUI_Intermediate · Drill 8 (NavigationStack path)",
        // 36 conceptual: Lazy stack performance — verbal
        37: "01_SwiftUI_Fundamentals · Drill 6 (ForEach sections)",
        // 38 conceptual: ViewBuilder under the hood — verbal
        39: "02_SwiftUI_Intermediate · Drill 9 (AnyLayout switch)",
        40: "01_SwiftUI_Fundamentals · Drill 7 (Environment vs EnvObject)",

        // Architecture (11–15 original, 41–50 added) — most are verbal
        // 11 verbal: MVVM vs TCA
        12: "02_SwiftUI_Intermediate · Drill 1 (Environment DI)",
        // 13 verbal: strangler-fig refactor
        14: "02_SwiftUI_Intermediate · Drill 5 (data-driven nav)",
        // 15 verbal: Repository
        // 41–50 mostly verbal/architectural; few drills:
        43: "06_Classic_Algos · Drill 6 (factory)",
        46: "06_Classic_Algos · Drill 7 (deep linking)",

        // SwiftCore (16–20 original, 51–60 added) → Pages 04 & 05
        16: "04_Generics_PAT · Drill 1 (some vs any)",
        17: "05_ARC_Memory · Drill 1 (Combine retain cycle)",
        18: "05_ARC_Memory · Drills 3+4 (CoW)",
        19: "04_Generics_PAT · Drill 5 (firstDuplicate)",
        20: "05_ARC_Memory · Drill 5 (Task captures vs sink)",
        51: "04_Generics_PAT · Drill 6 (KeyPath erasure)",
        52: "04_Generics_PAT · Drill 7 (conditional conformance)",
        53: "04_Generics_PAT · Drill 8 (where clauses)",
        54: "04_Generics_PAT · Drill 9 (dynamicMemberLookup)",
        // 55 verbal: macros architecture
        56: "05_ARC_Memory · Drill 6 (property wrapper composition)",
        57: "05_ARC_Memory · Drill 7 (AnyHashable performance)"
        // 58–60 verbal
    ]
}
