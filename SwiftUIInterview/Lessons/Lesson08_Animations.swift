import SwiftUI

// MARK: - Lesson 08 — Animations
//
// `withAnimation { }` wraps state changes.
// `matchedGeometryEffect` builds "hero" transitions between views.

struct Lesson08View: View {
    @State private var expanded = false
    @State private var rotation: Double = 0
    @State private var selected = 0
    @Namespace private var ns

    var body: some View {
        LessonScaffold(
            title: "08 — Animations",
            goal: "Animate layout and state changes with springs and matched geometry.",
            exercise: """
            1. Apply `.transition(.scale.combined(with: .opacity))` to the expanded card.
            2. Build a segmented `Picker` animated via matchedGeometryEffect.
            3. Bonus: drag gesture that springs back on release.
            """
        ) {
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: expanded ? 200 : 80)
                    .overlay(Text(expanded ? "Collapse" : "Expand").foregroundStyle(.white))
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
                            expanded.toggle()
                        }
                    }

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 50))
                    .rotationEffect(.degrees(rotation))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.6)) { rotation += 180 }
                    }

                HStack(spacing: 0) {
                    ForEach(0..<3) { i in
                        ZStack {
                            if selected == i {
                                Capsule().fill(.tint)
                                    .matchedGeometryEffect(id: "pill", in: ns)
                            }
                            Text("Tab \(i+1)")
                                .foregroundStyle(selected == i ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(.spring) { selected = i }
                        }
                    }
                }
                .padding(4)
                .background(.quaternary.opacity(0.4), in: Capsule())
            }
        }
    }
}

#Preview { NavigationStack { Lesson08View() } }
