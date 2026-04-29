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
            1. Create a `StepperRow` subview that takes `@Binding var value: Int` \
            and shows + / − buttons.
            2. Replace the buttons below with your subview.
            3. Add a "Reset" button that zeroes every state value.
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
                ToggleRow(label: "Notifications", isOn: $isOn)
            }
            
            GroupBox("TextField") {
                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                Text(name.isEmpty ? "—" : "Hello, \(name)!")
                    .foregroundStyle(.secondary)
            }
            
            GroupBox("Text") {
                StepperRow(value: $counter)
            }
            
            Button {
                counter = 0
            } label: {
                Text("reset")
            }

            SolutionDisclosure(title: "Show reference solution") {
                CodeBlock("""
                struct StepperRow: View {
                    @Binding var value: Int
                    var body: some View {
                        HStack {
                            Button("−") { value -= 1 }
                            Text("\\(value)")
                                .font(.title2).monospacedDigit()
                                .frame(minWidth: 40)
                            Button("+") { value += 1 }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // Parent:
                StepperRow(value: $counter)

                Button("Reset all") {
                    counter = 0; isOn = false; name = ""
                }
                """)
            }
        }
    }
    struct StepperRow: View {
        @Binding var value: Int
        var body: some View {
            HStack {
                Button("−") { value -= 1 }
                Text("\(value)").font(.title2).monospacedDigit()
                Button("+") { value += 1 }
            }
            .buttonStyle(.bordered)
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
