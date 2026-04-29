import SwiftUI

// MARK: - Lesson 01 — @State and @Binding
//
// Core ideas:
// - @State: local source of truth for a View. Use for value types (struct/Int/Bool/String).
// - @Binding: a bidirectional reference to a @State owned by another view.
// - Data flow: pass data down as Binding, push events up via closures or via Binding mutation.

struct Lesson01View: View {
    @State private var counter = 0
    @State private var isOn = false
    @State private var name = ""

    var body: some View {
        LessonScaffold(
            title: "01 — @State / @Binding",
            goal: "Understand unidirectional data flow and how to share state between views.",
            exercise: """
            ✅ SOLVED on this branch — see StepperRow and the Reset button below.
            """
        ) {
            GroupBox("Counter (StepperRow + Binding)") {
                StepperRow(value: $counter)
            }

            GroupBox("Toggle (Binding)") {
                ToggleRow(label: "Notifications", isOn: $isOn)
            }

            GroupBox("TextField") {
                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                Text(name.isEmpty ? "—" : "Hello, \(name)!")
                    .foregroundStyle(.secondary)
            }

            Button("Reset all") {
                counter = 0
                isOn = false
                name = ""
            }
            .buttonStyle(.bordered)
        }
    }
}

// Exercise 1 + 2 solution
private struct StepperRow: View {
    @Binding var value: Int

    var body: some View {
        HStack {
            Button("−") { value -= 1 }
            Text("\(value)").font(.title2).monospacedDigit().frame(minWidth: 40)
            Button("+") { value += 1 }
        }
        .buttonStyle(.bordered)
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
