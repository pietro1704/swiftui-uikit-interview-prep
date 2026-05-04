import SwiftUI

/// Collapsible "Show solution" panel rendered inside a lesson.
/// Use it to surface a hint or a fully worked solution without leaving the lesson.
struct SolutionDisclosure<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @State private var expanded = false

    init(title: String = "Show solution", @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                    Text(expanded ? "Hide solution" : title)
                    Spacer()
                    Image(systemName: "key.fill")
                }
                .font(.callout.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.green)

            if expanded {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.green.opacity(0.4)))
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

/// Presents a code snippet with monospaced styling.
struct CodeBlock: View {
    let code: String

    init(_ code: String) { self.code = code }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.caption.monospaced())
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.white)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
