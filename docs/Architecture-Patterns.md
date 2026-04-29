# 🏛 iOS Architecture Patterns

## MVC (classic Apple)

```
Model ←→ Controller ←→ View
```

- ✅ Simple, the Apple default
- ❌ View Controllers tend to bloat ("Massive View Controller")
- 📍 Still common in small apps and legacy code

## MVVM (most common today)

```
Model ←→ ViewModel ←→ View
              ↑ binding
```

```swift
@Observable
final class HomeViewModel {
    var items: [Item] = []
    func load() async { items = await repo.fetchAll() }
}

struct HomeView: View {
    @State private var vm = HomeViewModel()
    var body: some View {
        List(vm.items, ...)
            .task { await vm.load() }
    }
}
```

- ✅ Testable (the VM is plain Swift)
- ✅ Decouples logic from view
- 📍 Default for modern SwiftUI projects

## VIPER

```
View ←→ Presenter ←→ Interactor ←→ Entity
              ↑
            Router
```

- ✅ Strict separation of responsibilities
- ❌ A lot of boilerplate for small apps
- 📍 Common in large enterprise apps (banking, etc.)

## TCA — The Composable Architecture

```
Action → Reducer(State, Action) → State'
```

- ✅ Single state, redux-like, highly testable
- ❌ Learning curve, external dependency
- 📍 Great fit for apps with complex state flows

## Coordinator

A pattern to remove navigation logic from view controllers.

```swift
protocol Coordinator {
    var navigationController: UINavigationController { get set }
    func start()
}

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    func start() {
        let vc = HomeViewController()
        vc.onTapItem = { [weak self] item in self?.showDetail(item) }
        navigationController.pushViewController(vc, animated: false)
    }
    private func showDetail(_ item: Item) { /* ... */ }
}
```

- ✅ View controllers don't know about other screens
- 📍 Almost mandatory in large UIKit apps

## How to choose

| App size | Recommendation |
|----------|----------------|
| < 10 screens | MVVM |
| 10–50 screens | MVVM + Coordinator + manual DI |
| 50+ screens, large team | Modular MVVM or TCA |
| Mostly legacy UIKit + Storyboards | MVC, with targeted MVVM refactors |

> 💡 Don't fall in love with the framework — fall in love with the problem. Architecture is a *means*, not an end.
