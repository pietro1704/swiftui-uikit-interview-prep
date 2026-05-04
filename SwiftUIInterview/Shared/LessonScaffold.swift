import SwiftUI
import Inject

private struct HotReload: ViewModifier {
    @ObserveInjection var inject
    func body(content: Content) -> some View {
        content.enableInjection()
    }
}

extension View {
    func hotReload() -> some View { modifier(HotReload()) }
}

// MARK: - Reusable boxes

struct LessonGoalBox: View {
    let goal: String
    var body: some View {
        Label(goal, systemImage: "target")
            .font(.callout)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct LessonExerciseBox: View {
    let exercise: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Exercise", systemImage: "pencil.and.outline")
                .font(.headline)
            Text(exercise)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.orange.opacity(0.5)))
    }
}

// MARK: - Default scaffold (ScrollView-based — fine for non-List lessons)

struct LessonScaffold<Content: View>: View {
    let title: String
    let goal: String
    let exercise: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LessonGoalBox(goal: goal)
                content
                LessonExerciseBox(exercise: exercise)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .hotReload()
    }
}
