# 📱 SwiftUI + UIKit Interview Prep

> App iOS interativo para estudar **SwiftUI**, **UIKit** e **Swift Concurrency** — do básico ao avançado — em formato de lições com exercícios.

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Made with ❤️](https://img.shields.io/badge/Made%20with-%E2%9D%A4%EF%B8%8F-red.svg)](https://github.com/pietro1704)

Cada lição vive em uma tela do app: você lê o exemplo, brinca com o estado, e completa um **exercício TODO** comentado no código.

---

## ✨ Conteúdo

| #  | Lição | Tópico |
|----|-------|--------|
| 01 | `@State` & `@Binding` | Fluxo unidirecional, fonte da verdade |
| 02 | `List` & `ForEach` | Identifiable, swipe actions, edição |
| 03 | `NavigationStack` | Path programático, rotas tipadas |
| 04 | Form & validação | TextField, Picker, computed validators |
| 05 | `@Observable` + MVVM | Macro Observation (iOS 17+) |
| 06 | async/await + URLSession | Idle/loading/loaded/failed |
| 07 | Combine | Publishers, debounce em search |
| 08 | Animações | withAnimation, matchedGeometryEffect |
| 09 | SwiftData | `@Model`, `@Query`, `ModelContext` |
| 10 | Testes | XCTest no ViewModel |
| 11 | **Interop UIKit ↔ SwiftUI** | UIViewRepresentable, UIHostingController |
| 12 | **UIKit avançado** | Compositional Layout, Diffable Data Source, Custom UIControl |
| 13 | **SwiftUI avançado** | PreferenceKey, GeometryReader, ViewModifier, Environment custom |
| 14 | **Concurrency avançada** | TaskGroup, actor, AsyncStream, MainActor |

---

## 🚀 Começando

### Pré-requisitos
- macOS 14+
- Xcode 15+ (testado em 26.3)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Setup

```bash
git clone git@github.com:pietro1704/swiftui-uikit-interview-prep.git
cd swiftui-uikit-interview-prep
xcodegen generate
open SwiftUIInterview.xcodeproj
```

Pressione **▶️ Run** no Xcode (ou `Cmd+R`).

### Rodar testes

```bash
# pelo Xcode: Cmd+U
xcodebuild -project SwiftUIInterview.xcodeproj \
           -scheme SwiftUIInterview \
           -destination 'platform=iOS Simulator,name=iPhone 15' test
```

---

## 📚 Como estudar

1. **Abra a lição no app** → leia o cartão "Goal" no topo.
2. **Mexa nos controles** para ver os efeitos do estado.
3. **Abra o arquivo** correspondente em `SwiftUIInterview/Lessons/` no Xcode.
4. **Complete o exercício TODO** descrito no cartão laranja.
5. **Faça commit** da sua solução numa branch e abra PR pra você mesmo (treina fluxo de PR).

> 💡 Veja a [Wiki](../../wiki) para o roteiro de estudo dia-a-dia + 50 perguntas comuns de entrevista iOS.

---

## 🏛 Arquitetura

```
SwiftUIInterview/
├── App/
│   ├── SwiftUIInterviewApp.swift   # @main, ModelContainer
│   └── ContentView.swift            # NavigationStack + lista de lições
├── Lessons/
│   ├── Lesson01_StateBinding.swift
│   ├── Lesson02_Lists.swift
│   ├── ...
│   └── Lesson14_ConcurrencyAdvanced.swift
├── Shared/
│   └── LessonScaffold.swift         # Template visual de cada lição
└── Resources/

SwiftUIInterviewTests/
└── CounterViewModelTests.swift
```

**Padrão MVVM** com `@Observable` (iOS 17+).
**Sem dependências externas** — só Apple frameworks.

---

## 🎯 Para entrevistas iOS

Tópicos cobertos cobrem ~90% do que costuma cair em entrevistas técnicas para vagas iOS Pleno/Sênior:

- ✅ State management (`@State`, `@Binding`, `@Observable`)
- ✅ Navegação moderna (`NavigationStack`)
- ✅ Concorrência estruturada (async/await, actors, TaskGroup)
- ✅ Persistência (SwiftData)
- ✅ Reativo (Combine)
- ✅ Interop UIKit (Representable, HostingController, Coordinator)
- ✅ UIKit avançado (Compositional, Diffable, Auto Layout)
- ✅ Testes unitários

---

## 🤝 Contribuindo

PRs são muito bem-vindos! Especialmente:
- Novas lições (Charts, MapKit avançado, WidgetKit, App Intents…)
- Tradução para inglês/espanhol
- Correções e melhorias didáticas

```bash
git checkout -b feature/minha-licao
# ... edite ...
git commit -m "feat: add lesson X"
git push origin feature/minha-licao
```

---

## 📄 Licença

[MIT](LICENSE) — use, fork, modifique à vontade.

---

<p align="center">
  Feito com 🍎 para a comunidade iOS BR.
  <br>
  <a href="https://github.com/pietro1704">@pietro1704</a>
</p>
