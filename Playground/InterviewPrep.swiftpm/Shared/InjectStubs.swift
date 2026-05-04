import SwiftUI

// MARK: - Inject hot-reload stubs
//
// The Xcode app variant of this project depends on krzysztofzablocki/Inject
// for code injection during development. The Swift Playgrounds (.swiftpm)
// variant cannot pull in that SPM package on iPad, so this file provides
// no-op shims with the same API surface used throughout the lessons:
//
//   .enableInjection()   →  passthrough
//   @ObserveInjection    →  always returns 0
//   .hotReload()         →  passthrough
//
// Result: every lesson file compiles untouched in both targets.

extension View {
    @inline(__always)
    public func enableInjection() -> some View { self }

    @inline(__always)
    public func loadInjection() -> some View { self }

    @inline(__always)
    public func onInjection(bumpState: @escaping () -> Void) -> some View { self }
}

@available(iOS 13.0, *)
@propertyWrapper
public struct ObserveInjection {
    public init() {}
    public private(set) var wrappedValue: Int {
        get { 0 }
        set {}
    }
}
