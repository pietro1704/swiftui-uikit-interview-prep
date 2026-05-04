import SwiftUI

// MARK: - Result screen
//
// Score, breakdown by topic, and a per-question review row that surfaces
// the explanation + reference solution next to whatever the candidate typed.
// Modeled after a tech-lead debrief: "Where did you get pulled, and what
// would the canonical answer have looked like?"

struct MockInterviewResultView: View {
    let state: MockInterviewState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScoreCard(state: state)
                TopicBreakdown(state: state)
                ReviewList(state: state)
                Button {
                    state.reset()
                } label: {
                    Label("Restart interview", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

// MARK: - Score card

private struct ScoreCard: View {
    let state: MockInterviewState

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle()
                    .stroke(.tint.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(state.scorePercent) / 100)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(state.scorePercent)%")
                    .font(.title.weight(.bold).monospacedDigit())
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 4) {
                Text(verdict)
                    .font(.title3.weight(.semibold))
                Text("\(state.correctCount) of \(state.totalCount) correct")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    private var verdict: String {
        switch state.scorePercent {
        case 90...:    "Staff-level depth"
        case 75..<90:  "Senior, with confidence"
        case 60..<75:  "Senior, polish gaps"
        case 40..<60:  "Mid-level — review fundamentals"
        default:       "Strong gaps to address"
        }
    }
}

// MARK: - Topic breakdown

private struct TopicBreakdown: View {
    let state: MockInterviewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By topic").font(.headline)
            ForEach(QuestionTopic.allCases) { topic in
                let correct = state.correctCount(for: topic)
                let total = state.totalCount(for: topic)
                HStack(spacing: 10) {
                    Image(systemName: topic.icon)
                        .frame(width: 22)
                        .foregroundStyle(.tint)
                    Text(topic.rawValue)
                        .font(.callout)
                    Spacer()
                    Text("\(correct)/\(total)")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(correct == total ? .green : .secondary)
                }
                .padding(.vertical, 4)
                ProgressView(value: Double(correct), total: Double(max(total, 1)))
                    .tint(correct == total ? .green : .accentColor)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.secondary.opacity(0.2)))
    }
}

// MARK: - Review list

private struct ReviewList: View {
    let state: MockInterviewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Question review").font(.headline)
            ForEach(state.questions) { q in
                ReviewRow(question: q, state: state)
            }
        }
    }
}

private struct ReviewRow: View {
    let question: Question
    let state: MockInterviewState

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: outcomeIcon)
                        .foregroundStyle(outcomeColor)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Q\(question.id) · \(question.topic.rawValue)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(.init(question.prompt))   // markdown
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .lineLimit(expanded ? nil : 2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let chosen = state.selection(for: question) {
                        Text(.init("Your answer: \(question.options[chosen])"))
                            .font(.footnote)
                            .foregroundStyle(state.isCorrect(question) ? .green : .red)
                    } else {
                        Text("Skipped")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text(.init("Correct: \(question.options[question.correctIndex])"))
                        .font(.footnote)
                        .foregroundStyle(.green)
                    Text(.init(question.explanation))   // markdown
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    DisclosureGroup("Reference solution") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(question.referenceSolution)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color.indigo.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                    }
                    .font(.footnote.weight(.medium))
                }
                .padding(.leading, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.secondary.opacity(0.2)))
    }

    private var outcomeIcon: String {
        guard state.selection(for: question) != nil else { return "minus.circle" }
        return state.isCorrect(question) ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    private var outcomeColor: Color {
        guard state.selection(for: question) != nil else { return .secondary }
        return state.isCorrect(question) ? .green : .red
    }
}

#Preview {
    let s = MockInterviewState()
    s.select(option: 1, for: s.questions[0])
    s.select(option: 0, for: s.questions[1])
    s.finish()
    return NavigationStack { MockInterviewResultView(state: s) }
}
