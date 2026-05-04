import SwiftUI

// MARK: - Senior mock interview — side-by-side quiz
//
// Left pane: question prompt + multiple-choice options + reveal panel.
// Right pane: livecoding sandbox (TextEditor) with a starter snippet that
// the candidate edits during the explanation.
//
// On compact width (iPhone portrait) the panes stack into a TabView so each
// half stays usable. On regular width (iPad / iPhone Pro Max landscape) it's
// a true HStack, mimicking what a remote-pair interview screen looks like.

struct MockInterviewView: View {
    @State private var state = MockInterviewState()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if state.isFinished {
                MockInterviewResultView(state: state)
            } else {
                quiz
            }
        }
        .navigationTitle("Senior Mock Interview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Restart", systemImage: "arrow.counterclockwise") { state.reset() }
                    Button("Jump to results", systemImage: "checkmark.seal") { state.finish() }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .enableInjection()
    }

    @ViewBuilder
    private var quiz: some View {
        VStack(spacing: 0) {
            ProgressHeader(state: state)
                .padding(.horizontal)
                .padding(.top, 8)

            if sizeClass == .regular {
                HStack(spacing: 0) {
                    QuestionPane(state: state)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Divider()
                    LiveCodingPane(state: state)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                TabView {
                    QuestionPane(state: state)
                        .tabItem { Label("Question", systemImage: "questionmark.circle") }
                    LiveCodingPane(state: state)
                        .tabItem { Label("Code", systemImage: "chevron.left.slash.chevron.right") }
                }
            }

            BottomBar(state: state)
                .padding()
                .background(.ultraThinMaterial)
        }
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

// MARK: - Progress header

private struct ProgressHeader: View {
    let state: MockInterviewState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(state.current.topic.rawValue, systemImage: state.current.topic.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Spacer()
                Text("\(state.currentIndex + 1)/\(state.totalCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(state.currentIndex + 1), total: Double(state.totalCount))
                .progressViewStyle(.linear)
        }
    }
}

// MARK: - Question pane

private struct QuestionPane: View {
    let state: MockInterviewState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(state.current.prompt)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                VStack(spacing: 8) {
                    ForEach(Array(state.current.options.enumerated()), id: \.offset) { idx, label in
                        OptionButton(
                            label: label,
                            index: idx,
                            isSelected: state.selection(for: state.current) == idx,
                            isRevealed: state.isRevealed(state.current),
                            correctIndex: state.current.correctIndex
                        ) {
                            state.select(option: idx, for: state.current)
                        }
                    }
                }

                if state.isRevealed(state.current) {
                    SolutionPanel(question: state.current, state: state)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.2), value: state.isRevealed(state.current))
        }
    }
}

private struct OptionButton: View {
    let label: String
    let index: Int
    let isSelected: Bool
    let isRevealed: Bool
    let correctIndex: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: marker)
                    .foregroundStyle(markerColor)
                    .font(.title3)
                Text(label)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isRevealed)
    }

    private var marker: String {
        if isRevealed {
            if index == correctIndex { return "checkmark.circle.fill" }
            if isSelected             { return "xmark.circle.fill" }
            return "circle"
        }
        return isSelected ? "largecircle.fill.circle" : "circle"
    }
    private var markerColor: Color {
        if isRevealed {
            if index == correctIndex { return .green }
            if isSelected             { return .red }
            return .secondary
        }
        return isSelected ? .accentColor : .secondary
    }
    private var background: Color {
        if isRevealed {
            if index == correctIndex { return .green.opacity(0.12) }
            if isSelected             { return .red.opacity(0.10) }
        }
        return isSelected ? .accentColor.opacity(0.10) : .clear
    }
    private var border: Color {
        if isRevealed {
            if index == correctIndex { return .green.opacity(0.6) }
            if isSelected             { return .red.opacity(0.5) }
        }
        return isSelected ? .accentColor.opacity(0.4) : .secondary.opacity(0.25)
    }
}

private struct SolutionPanel: View {
    let question: Question
    let state: MockInterviewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: state.isCorrect(question) ? "checkmark.seal.fill" : "info.circle.fill")
                    .foregroundStyle(state.isCorrect(question) ? .green : .orange)
                Text(state.isCorrect(question) ? "Correct" : "Why this answer")
                    .font(.headline)
            }
            Text(question.explanation)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.green.opacity(0.3)))
    }
}

// MARK: - Live coding pane

private struct LiveCodingPane: View {
    let state: MockInterviewState
    @State private var showReference: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Livecoding", systemImage: "chevron.left.slash.chevron.right")
                    .font(.headline)
                Spacer()
                Button {
                    state.typedCode[state.current.id] = state.current.starterCode
                } label: {
                    Label("Reset snippet", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            TextEditor(text: bindingForCurrent)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .frame(maxHeight: .infinity)

            if state.isRevealed(state.current) {
                DisclosureGroup(isExpanded: $showReference) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(state.current.referenceSolution)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.indigo.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                } label: {
                    Label("Reference solution", systemImage: "key.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.indigo)
                }
            }
        }
        .padding()
    }

    private var bindingForCurrent: Binding<String> {
        Binding(
            get: { state.typedCode[state.current.id] ?? state.current.starterCode },
            set: { state.typedCode[state.current.id] = $0 }
        )
    }
}

// MARK: - Bottom bar

private struct BottomBar: View {
    let state: MockInterviewState

    var body: some View {
        HStack(spacing: 12) {
            Button {
                state.previous()
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(!state.canGoPrev)

            Spacer()

            if !state.isRevealed(state.current) {
                Button {
                    state.reveal(state.current)
                } label: {
                    Label("Reveal", systemImage: "key.fill")
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(state.selection(for: state.current) == nil)
            }

            Spacer()

            if state.canGoNext {
                Button {
                    state.next()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(TrailingIconLabelStyle())
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    state.finish()
                } label: {
                    Label("Finish", systemImage: "checkmark.seal")
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

#Preview {
    NavigationStack { MockInterviewView() }
}
