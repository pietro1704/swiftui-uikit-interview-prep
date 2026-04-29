import SwiftUI

// MARK: - Lição 10 — Testes
//
// Para entrevista: foque em testar ViewModels (não a view).
// O CounterViewModel da lição 05 já é testável pois é puro Swift.

struct Lesson10View: View {
    var body: some View {
        LessonScaffold(
            title: "10 — Testes",
            goal: "Estruturar ViewModels testáveis e escrever XCTest cases.",
            exercise: """
            Veja o arquivo `SwiftUIInterviewTests/CounterViewModelTests.swift`.

            1. Adicione um teste para `decrement()` quando count == 0 (não deve ficar negativo).
            2. Teste o histórico depois de 3 increments + 1 decrement.
            3. Bônus: crie um protocolo `Clock` injetado no VM para testar tempo.
            """
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Cmd+U no Xcode roda os testes", systemImage: "play.circle")
                Label("Use injeção de dependências p/ isolar I/O", systemImage: "arrow.triangle.merge")
                Label("Testes de Snapshot p/ UI (lib pointfreeco)", systemImage: "camera")
            }
        }
    }
}

#Preview { NavigationStack { Lesson10View() } }
