import SwiftUI

// MARK: - Lição 04 — Form & validação
//
// Form é uma List estilizada para inputs. Combine com computed properties para validação derivada.

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
            goal: "Formulários com validação reativa baseada em computed properties.",
            exercise: """
            1. Adicione confirmação de senha com mensagem de erro inline.
            2. Mostre `ProgressView` ao submeter e desabilite o botão.
            3. Bônus: extraia validação para um struct `SignUpValidator` testável.
            """
        ) {
            Form {
                Section("Conta") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    if !email.isEmpty && !isEmailValid {
                        Text("Email inválido").font(.caption).foregroundStyle(.red)
                    }
                    SecureField("Senha (≥ 8)", text: $password)
                    if !password.isEmpty && !isPasswordValid {
                        Text("Senha curta").font(.caption).foregroundStyle(.red)
                    }
                }

                Section("Perfil") {
                    Picker("Cargo", selection: $role) {
                        ForEach(Role.allCases) { Text($0.rawValue).tag($0) }
                    }
                    VStack(alignment: .leading) {
                        Text("Experiência: \(Int(experience)) anos")
                        Slider(value: $experience, in: 0...20, step: 1)
                    }
                    Toggle("Aceito os termos", isOn: $acceptsTerms)
                }

                Section {
                    Button("Cadastrar") { /* TODO submit */ }
                        .disabled(!canSubmit)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(minHeight: 520)
        }
    }
}

#Preview { NavigationStack { Lesson04View() } }
