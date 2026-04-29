import SwiftUI

// MARK: - Lição 01 — @State e @Binding
//
// Conceitos:
// - @State: fonte da verdade local de uma View. Use para tipos `value` (struct/Int/Bool/String).
// - @Binding: referência bidirecional para um @State pertencente a outra view.
// - Fluxo: dados descem como Binding, eventos sobem por closures ou mutação via Binding.

struct Lesson01View: View {
    @State private var counter = 0
    @State private var isOn = false
    @State private var name = ""

    var body: some View {
        LessonScaffold(
            title: "01 — @State / @Binding",
            goal: "Entender o fluxo unidirecional e como compartilhar estado entre views.",
            exercise: """
            1. Crie uma subview `StepperRow` que recebe `@Binding var value: Int` \
            e exibe + / − para incrementar.
            2. Substitua os botões abaixo pela sua subview.
            3. Adicione um botão "Reset" que zera todos os estados.
            """
        ) {
            GroupBox("Counter") {
                HStack {
                    Button("−") { counter -= 1 }
                    Text("\(counter)").font(.title2).monospacedDigit()
                    Button("+") { counter += 1 }
                }
                .buttonStyle(.bordered)
            }

            GroupBox("Toggle (Binding)") {
                ToggleRow(label: "Notificações", isOn: $isOn)
            }

            GroupBox("TextField") {
                TextField("Seu nome", text: $name)
                    .textFieldStyle(.roundedBorder)
                Text(name.isEmpty ? "—" : "Olá, \(name)!")
                    .foregroundStyle(.secondary)
            }

            // TODO (exercício): troque os botões do counter por StepperRow(value: $counter)
            //
            // struct StepperRow: View {
            //     @Binding var value: Int
            //     var body: some View { ... }
            // }
        }
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(label, isOn: $isOn)
    }
}

#Preview { NavigationStack { Lesson01View() } }
