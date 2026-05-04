import SwiftUI
import SwiftData

// Entry point for the playground (.swiftpm) variant of the app.
// SwiftData container is registered for Lesson 09 (TaskItem).
// All `enableInjection()` / `@ObserveInjection` calls in lesson files are
// resolved by `InjectStubs.swift` to no-ops — the playground does NOT pull
// in the Inject SPM package, since it doesn't run in Swift Playgrounds on iPad.

@main
struct InterviewPrepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TaskItem.self])
    }
}
