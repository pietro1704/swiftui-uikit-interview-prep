import Foundation
import Observation

// MARK: - Mock interview state machine
//
// Holds the candidate's progression through the question bank: current index,
// per-question selection, candidate-typed code, scoring, and whether the
// question's solution has been revealed. Designed for the side-by-side
// interview view; survives navigation, drives the result screen.

@Observable
@MainActor
final class MockInterviewState {
    let questions: [Question]

    var currentIndex: Int = 0

    // Per-question state, keyed by Question.id.
    private(set) var selectedOption: [Int: Int] = [:]
    var typedCode: [Int: String] = [:]
    private(set) var revealed: Set<Int> = []

    // Once finished, show the result screen.
    var isFinished: Bool = false

    init(questions: [Question] = QuestionBank.all) {
        self.questions = questions
        for q in questions { typedCode[q.id] = q.starterCode }
    }

    // MARK: Navigation
    var current: Question { questions[currentIndex] }
    var canGoNext: Bool { currentIndex < questions.count - 1 }
    var canGoPrev: Bool { currentIndex > 0 }

    func next() {
        guard canGoNext else { return }
        currentIndex += 1
    }
    func previous() {
        guard canGoPrev else { return }
        currentIndex -= 1
    }
    func jump(to index: Int) {
        guard questions.indices.contains(index) else { return }
        currentIndex = index
    }

    // MARK: Answering

    func select(option index: Int, for question: Question) {
        selectedOption[question.id] = index
    }

    func reveal(_ question: Question) {
        revealed.insert(question.id)
    }

    func isRevealed(_ question: Question) -> Bool {
        revealed.contains(question.id)
    }

    func selection(for question: Question) -> Int? {
        selectedOption[question.id]
    }

    func isCorrect(_ question: Question) -> Bool {
        selectedOption[question.id] == question.correctIndex
    }

    // MARK: Scoring

    var answeredCount: Int { selectedOption.count }

    var correctCount: Int {
        questions.reduce(into: 0) { acc, q in
            if selectedOption[q.id] == q.correctIndex { acc += 1 }
        }
    }

    var totalCount: Int { questions.count }

    var scorePercent: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalCount)) * 100)
    }

    func correctCount(for topic: QuestionTopic) -> Int {
        questions.filter { $0.topic == topic }.reduce(into: 0) { acc, q in
            if selectedOption[q.id] == q.correctIndex { acc += 1 }
        }
    }

    func totalCount(for topic: QuestionTopic) -> Int {
        questions.filter { $0.topic == topic }.count
    }

    // MARK: Reset

    func reset() {
        currentIndex = 0
        selectedOption.removeAll()
        revealed.removeAll()
        isFinished = false
        for q in questions { typedCode[q.id] = q.starterCode }
    }

    func finish() { isFinished = true }
}
