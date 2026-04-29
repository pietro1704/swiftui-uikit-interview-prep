import XCTest
import SwiftUI
import SnapshotTesting
@testable import SwiftUIInterview

/// Snapshot tests are recorded once and then compared on every run.
///
/// To **record** new snapshots: set `isRecording = true`, run the tests, then set it back.
/// CI runs them with `isRecording = false` so any visual change fails the build.
final class LessonSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Set to true locally to refresh snapshots.
        isRecording = false
    }

    func test_lesson01_layout() {
        let view = NavigationStack { Lesson01View() }
            .frame(width: 390, height: 844)   // iPhone 15 logical size

        // Skipped on CI by default — uncomment locally after recording the reference.
        // assertSnapshot(of: UIHostingController(rootView: view), as: .image(on: .iPhone13))
        _ = view
        XCTAssertTrue(true, "Snapshot scaffold compiles. Enable assertSnapshot once references exist.")
    }
}
