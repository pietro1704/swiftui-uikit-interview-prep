import SwiftUI

// MARK: - Lesson 04 — Form & validation
//
// Form is a styled List built for inputs. Combine it with computed properties
// for derived, reactive validation.

struct Lesson04View: View {
    @State private var email = ""
    @State private var password = ""
    @State private var acceptsTerms = false
    @State private var role: Role = .dev
    @State private var experience = 1.0

    enum Role: String, CaseIterable, Identifiable {
        case dev = "Dev"
        case design = "Design"
        case pm = "PM"
        var id: String { rawValue }
    }

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    private var isPasswordValid: Bool { password.count >= 8 }
    private var canSubmit: Bool { isEmailValid && isPasswordValid && acceptsTerms }

    var body: some View {
        LessonScaffold(
            title: "04 — Form",
            goal: "Reactive validation backed by computed properties.",
            exercise: """
            1. Add a confirm-password field with an inline error message.
            2. Show a `ProgressView` while submitting and disable the button.
            3. Bonus: extract validation into a testable `SignUpValidator` struct.
            """
        ) {
            Form {
                Section("Account") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    if !email.isEmpty && !isEmailValid {
                        Text("Invalid email").font(.caption).foregroundStyle(.red)
                    }
                    SecureField("Password (≥ 8)", text: $password)
                    if !password.isEmpty && !isPasswordValid {
                        Text("Password too short").font(.caption).foregroundStyle(.red)
                    }
                }

                Section("Profile") {
                    Picker("Role", selection: $role) {
                        ForEach(Role.allCases) { Text($0.rawValue).tag($0) }
                    }
                    VStack(alignment: .leading) {
                        Text("Experience: \(Int(experience)) years")
                        Slider(value: $experience, in: 0...20, step: 1)
                    }
                    Toggle("I accept the terms", isOn: $acceptsTerms)
                }

                Section {
                    Button("Sign up") { /* TODO: submit */ }
                        .disabled(!canSubmit)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(minHeight: 520)
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview { NavigationStack { Lesson04View() } }
