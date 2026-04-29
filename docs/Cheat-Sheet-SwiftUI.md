# 🧠 SwiftUI Cheat Sheet

## Property wrappers (state)

| Wrapper | Scope | When to use |
|---------|-------|-------------|
| `@State` | Local view | Small value types (Bool, Int, struct) |
| `@Binding` | Shared | "Borrow" another view's `@State` |
| `@Observable` (macro) | Model | Replaces ObservableObject; auto tracking |
| `@Bindable` | View | Build Bindings from `@Observable` properties |
| `@Environment(\.x)` | Tree | Read a value injected by an ancestor |
| `@AppStorage("key")` | UserDefaults | Persist a primitive |
| `@SceneStorage("key")` | Scene | Per-scene persistence |
| `@FocusState` | View | Drive text field focus |
| `@Query` (SwiftData) | Model | Reactive fetch from `@Model` |

## Common modifiers

```swift
.padding()
.padding(.horizontal, 16)
.frame(maxWidth: .infinity)
.background(.tint, in: RoundedRectangle(cornerRadius: 8))
.foregroundStyle(.secondary)         // iOS 15+ replacement for .foregroundColor
.overlay(...)
.clipShape(Circle())
.shadow(radius: 4)
.task { await load() }                // async on appear
.onAppear { ... }                     // sync on appear
.refreshable { await reload() }       // pull-to-refresh
.searchable(text: $query)
.alert("Error", isPresented: $showError) { Button("OK") {} }
.confirmationDialog(...)
.sheet(isPresented: $show) { Modal() }
.fullScreenCover(...)
```

## Layout primitives

- `VStack`, `HStack`, `ZStack`, `LazyVStack`, `LazyHStack`
- `Grid`, `LazyVGrid(columns:)`, `LazyHGrid`
- `Spacer()` to push
- `Divider()` for separators
- `GeometryReader` to read size
- `Layout` protocol (iOS 16+) for fully custom layouts

## Navigation (iOS 16+)

```swift
NavigationStack(path: $path) {
    List {
        NavigationLink("Detail", value: 42)
    }
    .navigationDestination(for: Int.self) { id in
        DetailView(id: id)
    }
}
```

## Animations

```swift
withAnimation(.spring(duration: 0.4)) { isOn.toggle() }
withAnimation(.easeInOut) { ... }
.transition(.move(edge: .bottom).combined(with: .opacity))
.matchedGeometryEffect(id: "hero", in: ns)
```

## Custom EnvironmentValue

```swift
private struct ThemeKey: EnvironmentKey { static let defaultValue: Color = .blue }
extension EnvironmentValues {
    var theme: Color {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Usage:
SomeView().environment(\.theme, .purple)
```

## PreferenceKey (child → ancestor)

```swift
struct HeightPref: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

content
    .background(GeometryReader { g in
        Color.clear.preference(key: HeightPref.self, value: g.size.height)
    })
    .onPreferenceChange(HeightPref.self) { measured = $0 }
```
