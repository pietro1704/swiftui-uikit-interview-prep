import SwiftUI

struct Lesson: Identifiable, Hashable {
    let id: Int
    let title: String
    let summary: String
    let icon: String
    let topic: LessonTopic
}

enum LessonTopic: Hashable {
    case stateBinding
    case lists
    case navigation
    case forms
    case mvvm
    case asyncAwait
    case combine
    case animations
    case swiftData
    case testing
    case interop
    case uikitAdvanced
    case swiftUIAdvanced
    case concurrencyAdvanced
}

struct ContentView: View {
    let lessons: [Lesson] = [
        .init(id: 1, title: "01 — @State & @Binding", summary: "Estado local e fluxo unidirecional", icon: "switch.2", topic: .stateBinding),
        .init(id: 2, title: "02 — List & ForEach", summary: "Listas dinâmicas, swipe actions", icon: "list.bullet.rectangle", topic: .lists),
        .init(id: 3, title: "03 — NavigationStack", summary: "Navegação com path programático", icon: "arrow.forward.circle", topic: .navigation),
        .init(id: 4, title: "04 — Form & Validação", summary: "Formulários e regras de validação", icon: "checkmark.rectangle.stack", topic: .forms),
        .init(id: 5, title: "05 — @Observable + MVVM", summary: "Macro Observation e arquitetura", icon: "rectangle.stack", topic: .mvvm),
        .init(id: 6, title: "06 — async/await + URLSession", summary: "Concorrência moderna em rede", icon: "network", topic: .asyncAwait),
        .init(id: 7, title: "07 — Combine", summary: "Publishers, debounce em busca", icon: "antenna.radiowaves.left.and.right", topic: .combine),
        .init(id: 8, title: "08 — Animações", summary: "withAnimation, matchedGeometry", icon: "wand.and.stars", topic: .animations),
        .init(id: 9, title: "09 — SwiftData", summary: "@Model, @Query, persistência", icon: "externaldrive", topic: .swiftData),
        .init(id: 10, title: "10 — Testes", summary: "Unit tests do ViewModel", icon: "checkmark.shield", topic: .testing),
        .init(id: 11, title: "11 — Interop UIKit ↔ SwiftUI", summary: "Representable, HostingController", icon: "arrow.triangle.2.circlepath", topic: .interop),
        .init(id: 12, title: "12 — UIKit avançado", summary: "Compositional, Diffable, custom UIControl", icon: "square.grid.3x3", topic: .uikitAdvanced),
        .init(id: 13, title: "13 — SwiftUI avançado", summary: "PreferenceKey, GeometryReader, ViewModifier", icon: "puzzlepiece.extension", topic: .swiftUIAdvanced),
        .init(id: 14, title: "14 — Concurrency avançada", summary: "TaskGroup, actor, AsyncStream", icon: "cpu", topic: .concurrencyAdvanced),
    ]

    var body: some View {
        NavigationStack {
            List(lessons) { lesson in
                NavigationLink(value: lesson.topic) {
                    HStack(spacing: 14) {
                        Image(systemName: lesson.icon)
                            .font(.title2)
                            .frame(width: 36, height: 36)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lesson.title).font(.headline)
                            Text(lesson.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("SwiftUI Interview Prep")
            .navigationDestination(for: LessonTopic.self) { topic in
                lessonView(for: topic)
            }
        }
    }

    @ViewBuilder
    private func lessonView(for topic: LessonTopic) -> some View {
        switch topic {
        case .stateBinding: Lesson01View()
        case .lists:        Lesson02View()
        case .navigation:   Lesson03View()
        case .forms:        Lesson04View()
        case .mvvm:         Lesson05View()
        case .asyncAwait:   Lesson06View()
        case .combine:      Lesson07View()
        case .animations:   Lesson08View()
        case .swiftData:    Lesson09View()
        case .testing:      Lesson10View()
        case .interop:      Lesson11View()
        case .uikitAdvanced: Lesson12View()
        case .swiftUIAdvanced: Lesson13View()
        case .concurrencyAdvanced: Lesson14View()
        }
    }
}

#Preview {
    ContentView()
}
