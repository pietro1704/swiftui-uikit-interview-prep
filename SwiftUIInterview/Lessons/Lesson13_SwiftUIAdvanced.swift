import SwiftUI

// MARK: - Lição 13 — SwiftUI avançado
//
// Quatro pilares de SwiftUI avançado para entrevista:
//  1. PreferenceKey       — filhos enviam dados ao pai (oposto do Environment)
//  2. GeometryReader      — leitura de tamanho/posição
//  3. ViewModifier custom — encapsular estilo reutilizável
//  4. EnvironmentValues   — DI implícita via árvore de views

// 1) PreferenceKey: cada item informa sua altura ao pai
struct HeightPref: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// 2) ViewModifier custom
struct CardStyle: ViewModifier {
    var tint: Color = .blue
    func body(content: Content) -> some View {
        content
            .padding()
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(tint.opacity(0.4)))
    }
}
extension View {
    func card(tint: Color = .blue) -> some View { modifier(CardStyle(tint: tint)) }
}

// 3) EnvironmentValues custom
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}
extension EnvironmentValues {
    var theme: Color {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// 4) ViewBuilder em função
@ViewBuilder
private func badge(_ text: String, ok: Bool) -> some View {
    if ok {
        Label(text, systemImage: "checkmark.seal.fill").foregroundStyle(.green)
    } else {
        Label(text, systemImage: "xmark.seal.fill").foregroundStyle(.red)
    }
}

struct Lesson13View: View {
    @State private var measuredHeight: CGFloat = 0

    var body: some View {
        LessonScaffold(
            title: "13 — SwiftUI avançado",
            goal: "PreferenceKey, GeometryReader, ViewModifier, Environment custom, ViewBuilder.",
            exercise: """
            1. Crie um `AnchorPreferenceKey` para desenhar uma linha ligando 2 views.
            2. Faça um modifier `.shimmer()` que aplica gradient animado.
            3. Bônus: crie um Layout custom (protocol Layout, iOS 16+) tipo flow horizontal.
            """
        ) {
            GroupBox("ViewModifier custom") {
                Text("Card azul").card()
                Text("Card laranja").card(tint: .orange)
            }

            GroupBox("@Environment custom (theme)") {
                ThemedRow(label: "Default")
                ThemedRow(label: "Override → roxo").environment(\.theme, .purple)
            }

            GroupBox("GeometryReader + PreferenceKey") {
                Text("Conteúdo dinâmico aqui dentro\nde múltiplas linhas para medir.")
                    .padding()
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: HeightPref.self, value: geo.size.height)
                        }
                    )
                    .onPreferenceChange(HeightPref.self) { measuredHeight = $0 }
                Text("Altura medida: \(Int(measuredHeight))pt")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            GroupBox("@ViewBuilder helper") {
                badge("Compilou", ok: true)
                badge("Testes", ok: false)
            }
        }
    }
}

private struct ThemedRow: View {
    let label: String
    @Environment(\.theme) private var theme
    var body: some View {
        HStack {
            Circle().fill(theme).frame(width: 16, height: 16)
            Text(label)
        }
    }
}

#Preview { NavigationStack { Lesson13View() } }
