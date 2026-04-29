import SwiftUI

struct LessonScaffold<Content: View>: View {
    let title: String
    let goal: String
    let exercise: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label(goal, systemImage: "target")
                    .font(.callout)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                content

                VStack(alignment: .leading, spacing: 6) {
                    Label("Exercício", systemImage: "pencil.and.outline")
                        .font(.headline)
                    Text(exercise)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.orange.opacity(0.5)))
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
