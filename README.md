# 📱 SwiftUI + UIKit Interview Prep

> An interactive iOS playground to study **SwiftUI**, **UIKit** and **Swift Concurrency** — from fundamentals to advanced — through bite-size lessons with hands-on exercises.

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/pietro1704/swiftui-uikit-interview-prep/pulls)

Each lesson is a screen in the app: read the example, play with the live state, then complete the **TODO exercise** at the bottom of the file.

---

## ✨ Curriculum

| #  | Lesson | Topics |
|----|--------|--------|
| 01 | `@State` & `@Binding` | Single source of truth, unidirectional flow |
| 02 | `List` & `ForEach` | Identifiable, swipe actions, editing |
| 03 | `NavigationStack` | Programmatic path, typed routes |
| 04 | Form & validation | TextField, Picker, computed validators |
| 05 | `@Observable` + MVVM | The new Observation macro (iOS 17+) |
| 06 | async/await + URLSession | Idle / loading / loaded / failed states |
| 07 | Combine | Publishers, debounced search |
| 08 | Animations | `withAnimation`, `matchedGeometryEffect` |
| 09 | SwiftData | `@Model`, `@Query`, `ModelContext` |
| 10 | Testing | XCTest on ViewModels |
| 11 | **UIKit ↔ SwiftUI interop** | UIViewRepresentable, UIHostingController |
| 12 | **Advanced UIKit** | Compositional Layout, Diffable Data Source, Custom UIControl |
| 13 | **Advanced SwiftUI** | PreferenceKey, GeometryReader, custom ViewModifier, Environment |
| 14 | **Advanced concurrency** | TaskGroup, actor, AsyncStream, MainActor, Sendable |
| 15 | **App Lifecycle** | ScenePhase, UIApplicationDelegateAdaptor |
| 16 | **Accessibility** | VoiceOver, Dynamic Type, Reduce Motion, adjustable trait |
| 17 | **Swift deep dive** | Generics + PAT, `some` vs `any`, result builders, custom property wrappers |

---

## 🚀 Getting started

### Requirements
- macOS 14+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Setup

```bash
git clone git@github.com:pietro1704/swiftui-uikit-interview-prep.git
cd swiftui-uikit-interview-prep
xcodegen generate
open SwiftUIInterview.xcodeproj
```

Hit **▶️ Run** (or `⌘R`) in Xcode.

### Run tests

```bash
# In Xcode: ⌘U
xcodebuild -project SwiftUIInterview.xcodeproj \
           -scheme SwiftUIInterview \
           -destination 'platform=iOS Simulator,name=iPhone 15' test
```

---

## 📚 How to study

1. **Open the lesson in the app** → read the goal at the top.
2. **Interact with the controls** to feel the state changes.
3. **Open the matching file** in `SwiftUIInterview/Lessons/` in Xcode.
4. **Complete the TODO** described in the orange "Exercise" card.
5. **Commit your solution** in a branch — practice the PR flow on yourself.

> 💡 See the [`docs/`](docs/) folder for: a **4-day fast track for senior engineers**, **50 mock interview questions**, and cheat sheets for SwiftUI, UIKit and Concurrency. Same content lives in the [Wiki](../../wiki).
>
> 🔑 Stuck? The [`solutions`](https://github.com/pietro1704/swiftui-uikit-interview-prep/tree/solutions) branch has worked answers for selected exercises.

---

## 🏛 Architecture

```
SwiftUIInterview/
├── App/
│   ├── SwiftUIInterviewApp.swift   # @main, ModelContainer
│   └── ContentView.swift            # NavigationStack + lesson list
├── Lessons/
│   ├── Lesson01_StateBinding.swift
│   ├── Lesson02_Lists.swift
│   ├── ...
│   └── Lesson14_ConcurrencyAdvanced.swift
├── Shared/
│   └── LessonScaffold.swift         # Visual scaffold for each lesson
└── Resources/

SwiftUIInterviewTests/
└── CounterViewModelTests.swift

docs/
├── Home.md
├── Fast-Track-Senior.md
├── Interview-Questions.md
├── Cheat-Sheet-SwiftUI.md
├── Cheat-Sheet-UIKit.md
├── Cheat-Sheet-Concurrency.md
├── Architecture-Patterns.md
└── Common-Pitfalls.md
```

**MVVM** with the `@Observable` macro (iOS 17+).
**One dev dependency** ([swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)) used only by the test target.

Tooling included: **SwiftLint** with a [pre-commit hook](.githooks/pre-commit), GitHub Actions **CI** running build + test + lint, and a [wiki sync workflow](.github/workflows/sync-wiki.yml).

---

## 🎯 Built for iOS interviews

The 14 lessons cover ~90% of what shows up in mid-level / senior iOS interviews:

- ✅ State management (`@State`, `@Binding`, `@Observable`)
- ✅ Modern navigation (`NavigationStack`)
- ✅ Structured concurrency (async/await, actors, TaskGroup, AsyncStream)
- ✅ Persistence (SwiftData)
- ✅ Reactive (Combine)
- ✅ UIKit interop (Representable, HostingController, Coordinator)
- ✅ Advanced UIKit (Compositional, Diffable, Auto Layout)
- ✅ Unit testing

---

## 🤝 Contributing

PRs are very welcome — especially:
- New lessons (Charts, MapKit, WidgetKit, App Intents…)
- Translations (pt-BR, es-LA)
- Didactic improvements

```bash
git checkout -b feat/my-lesson
# ... edit ...
git commit -m "feat: add lesson on Charts"
git push origin feat/my-lesson
```

---

## 📄 License

[MIT](LICENSE) — fork it, ship it, learn it.

---

<p align="center">
  Made with 🍎 for the iOS community.
  <br>
  <a href="https://github.com/pietro1704">@pietro1704</a>
</p>
