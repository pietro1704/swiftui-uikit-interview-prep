import SwiftUI

// MARK: - Lesson 10 — Testing
//
// For interviews: focus on testing ViewModels (not the view itself).
// The `CounterViewModel` from lesson 05 is already testable since it's pure Swift.

struct Lesson10View: View {
    var body: some View {
        LessonScaffold(
            title: "10 — Testing",
            goal: "Structure testable ViewModels and write XCTest cases.",
            exercise: """
            See `SwiftUIInterviewTests/CounterViewModelTests.swift`.

            1. Add a test for `decrement()` when count == 0 (should not go negative).
            2. Test the history after 3 increments + 1 decrement.
            3. Bonus: introduce a `Clock` protocol injected into the VM to test time.
            """
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Cmd+U in Xcode runs the tests", systemImage: "play.circle")
                Label("Use dependency injection to isolate IO", systemImage: "arrow.triangle.merge")
                Label("Snapshot testing for UI (pointfreeco lib)", systemImage: "camera")
            }
        }
    }
}

#Preview { NavigationStack { Lesson10View() } }
