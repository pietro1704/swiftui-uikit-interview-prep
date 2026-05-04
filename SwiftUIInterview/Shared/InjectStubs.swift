import SwiftUI

// MARK: - Inject hot-reload stubs (no-op)
//
// We removed the `Inject` SPM dependency to keep memory pressure low on
// 8GB Macs. Lesson files still call `enableInjection()` and declare
// `@ObserveInjection` — these no-ops let the existing didactic code
// compile unchanged. If you ever want hot-reload back, drop in the real
// SPM dep and delete this file.

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
        // swiftlint:disable:next unused_setter_value
        set {}
    }
}
