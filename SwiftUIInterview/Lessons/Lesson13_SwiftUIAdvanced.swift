import SwiftUI

// MARK: - Lesson 13 — Advanced SwiftUI
//
// Four pillars of advanced SwiftUI for interviews:
//  1. PreferenceKey         — children push data up to ancestors (opposite of Environment)
//  2. GeometryReader        — read size/position
//  3. Custom ViewModifier   — encapsulate reusable styling
//  4. EnvironmentValues     — implicit DI through the view tree

// 1) PreferenceKey: each item reports its own height to the parent
struct HeightPref: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// 2) Custom ViewModifier
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

// 3) Custom EnvironmentValues
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}
extension EnvironmentValues {
    var theme: Color {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// 4) ViewBuilder as a free function
@ViewBuilder
private func statusBadge(_ text: String, ok: Bool) -> some View {
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
            title: "13 — Advanced SwiftUI",
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
                statusBadge("Compilou", ok: true)
                statusBadge("Testes", ok: false)
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
