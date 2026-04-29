# 🐛 Common Pitfalls (and Interview Gotchas)

## SwiftUI

### 1. `@State` that doesn't update
```swift
// State holding a struct — assigning a new value works
struct User { var name: String }
@State var user = User(name: "")
Button("Update") { user.name = "Ana" }   // ✅ assigns to the @State
```
But if you put a **class instance** in `@State`, mutating its members **won't** trigger re-render. Use `@Observable`.

### 2. `@StateObject` vs `@ObservedObject`
```swift
// ❌ Recreates the VM on every re-render (bug)
struct V: View {
    @ObservedObject var vm = VM()
}

// ✅ Created once, retained
struct V: View {
    @StateObject var vm = VM()
}
```

### 3. `Task {}` vs `.task {}`
```swift
.onAppear {
    Task { await load() }   // ⚠️ doesn't cancel on disappear
}

.task { await load() }      // ✅ tied to view lifecycle
```

### 4. `ForEach` without a stable id
```swift
ForEach(0..<items.count) { i in ... }   // ❌ index shifts when array changes
ForEach(items, id: \.id) { item in ... } // ✅ or use Identifiable
```

### 5. `NavigationView` (deprecated)
Use `NavigationStack` on iOS 16+.

## UIKit

### 1. Forgetting `translatesAutoresizingMaskIntoConstraints = false`
Constraints don't take effect, the view collapses or disappears.

### 2. Closure retain cycle
```swift
api.fetch { result in
    self.handle(result)   // ❌ captures self strongly
}

api.fetch { [weak self] result in
    self?.handle(result)  // ✅
}
```

### 3. UI off the main thread
```swift
URLSession.shared.dataTask(with: url) { data, _, _ in
    self.label.text = "..."   // ❌ potential crash
}.resume()

// ✅
DispatchQueue.main.async {
    self.label.text = "..."
}
```

### 4. `prepare(for:sender:)` firing for the wrong segue
Forgetting to check `segue.identifier`.

### 5. `tableView.reloadData()` instead of batch updates
Bad performance and visible flicker. Use Diffable Data Source.

## Concurrency

### 1. Forgetting `await`
```swift
let user = loadUser()        // ❌ this returns a Task, not a User
let user = await loadUser()  // ✅
```

### 2. Actor reentrancy
```swift
actor Cache {
    var data: [String: Int] = [:]
    func loadAndStore(key: String) async {
        let v = await fetch()     // releases the actor lock
        // between the two lines another task could mutate data
        data[key] = v             // may overwrite a concurrent write
    }
}
```

### 3. Missing `@MainActor` on a SwiftUI VM
Triggers a "Publishing changes from background threads" warning.

### 4. `Task.detached` when you don't need it
You lose priority/cancellation/isolation inheritance. Only use with a clear reason.

### 5. Not cancelling streams
```swift
let task = Task {
    for await v in stream { ... }   // doesn't stop on its own
}
// .onDisappear { task.cancel() }
```

## Memory

### 1. `unowned` on something that might become nil
```swift
class Parent {
    var child: Child?
    init() { child = Child(parent: self) }
}
class Child {
    unowned let parent: Parent   // ❌ if parent goes nil, crash
    init(parent: Parent) { self.parent = parent }
}
// Use weak when nilability is possible.
```

### 2. NotificationCenter without removing observer
Block-based observers in iOS 9+ must be explicitly removed. Selector-based ones are auto-cleaned since iOS 9.

### 3. `Timer.scheduledTimer` retain cycle
```swift
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    self.tick()   // ❌ Timer retains self
}

Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.tick()  // ✅
}
```

---

> 🔥 **Top 3 most-asked**: retain cycles, `@StateObject` vs `@ObservedObject`, and `weak` vs `unowned`.
