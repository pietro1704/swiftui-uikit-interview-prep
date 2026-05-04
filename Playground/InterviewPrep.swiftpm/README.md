# InterviewPrep — Swift Playground variant

This is the **Swift Playground (.swiftpm)** variant of the SwiftUI / UIKit
interview-prep app. It mirrors every lesson and the senior mock-interview quiz
from the main Xcode project, but is built as a single SwiftPM-backed app
playground so it can run:

- in **Xcode** (faster, lighter than a full `.xcodeproj` on machines with
  limited RAM — the original use-case);
- in the **Swift Playgrounds** app on macOS or iPad.

## How to open

### Xcode (recommended on Mac)

```sh
open Playground/InterviewPrep.swiftpm
```

Pick a simulator (iPhone or iPad) and ⌘R.

### Swift Playgrounds (iPad / Mac)

Copy the `.swiftpm` folder to iCloud Drive, open it from the Files app, then
"Open in Swift Playgrounds." The app runs natively on-device.

## What's included

- **17 lessons** — same content as the main project (`Lesson01` … `Lesson17`).
- **Senior Mock Interview** — 20-question quiz (5 each on concurrency,
  advanced SwiftUI, architecture, Swift deep dive) with side-by-side livecoding
  pane on regular size classes.
- **`InjectStubs.swift`** — no-op shims for `enableInjection()` /
  `@ObserveInjection` so lesson files compile here without the Inject SPM
  package (which doesn't run inside Swift Playgrounds on iPad).

## Why two variants

| | Xcode project | `.swiftpm` playground |
|---|---|---|
| Hot reload via Inject | ✅ | ❌ (stubs no-op) |
| XCTest unit tests | ✅ | ❌ (Playgrounds limitation) |
| Snapshot tests | ✅ | ❌ |
| Memory footprint | heavy | lighter |
| Runs on iPad | ❌ | ✅ |
| Runs on Mac | ✅ | ✅ |

Use the Xcode project for the full dev loop (tests, hot reload). Use the
playground when you need a lighter iteration on a memory-constrained Mac, or
when studying on iPad.

## Layout

```
InterviewPrep.swiftpm/
├── Package.swift              # SwiftPM manifest, iOS 17+, executable target
├── AppMain/
│   ├── InterviewPrepApp.swift # @main, registers SwiftData container
│   └── ContentView.swift      # root list + navigation
├── Shared/
│   ├── LessonScaffold.swift   # reusable layout boxes
│   ├── SolutionDisclosure.swift
│   └── InjectStubs.swift      # no-op Inject API
├── Lessons/                   # Lesson01_StateBinding … Lesson17_SwiftDeepDive
└── MockInterview/             # QuestionBank, state, view, result
```
