import Foundation

// Aggregator that combines all topic-specific question lists into the
// 60-question bank served to the quiz UI. Individual lists live in
// `Questions+Concurrency.swift`, `Questions+SwiftUI.swift`,
// `Questions+Architecture.swift`, `Questions+SwiftCore.swift`.

enum QuestionBank {
    static let all: [Question] = concurrency + swiftUI + architecture + swiftCore
}
