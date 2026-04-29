import SwiftUI

// MARK: - Lição 08 — Animações
//
// `withAnimation { }` envolve mudanças de state.
// `matchedGeometryEffect` cria transições "hero" entre views.

struct Lesson08View: View {
    @State private var expanded = false
    @State private var rotation: Double = 0
    @State private var selected = 0
    @Namespace private var ns

    var body: some View {
        LessonScaffold(
            title: "08 — Animações",
            goal: "Animar mudanças de layout e estado com springs e matched geometry.",
            exercise: """
            1. Adicione `.transition(.scale.combined(with: .opacity))` ao card expandido.
            2. Crie um `Picker` segmentado animado com matchedGeometryEffect.
            3. Bônus: gesto de drag que volta com spring ao soltar.
            """
        ) {
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.tint.gradient)
                    .frame(height: expanded ? 200 : 80)
                    .overlay(Text(expanded ? "Recolher" : "Expandir").foregroundStyle(.white))
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
