import SwiftUI

// MARK: - Lesson 15 — App Lifecycle & Scenes
//
// SwiftUI replaces AppDelegate / SceneDelegate with the App protocol and Scene phases.
//
//  - @main App protocol: declarative entry, owns Scenes.
//  - WindowGroup / DocumentGroup / Settings: built-in scene types.
//  - @Environment(\.scenePhase): observe active / inactive / background transitions.
//  - UIApplicationDelegateAdaptor: bridge to UIKit for things SwiftUI doesn't expose
//    (push notifications, URL handling, Firebase config, etc.)

@Observable
final class LifecycleLog {
    private(set) var entries: [String] = []
    func add(_ s: String) {
        let t = Date().formatted(date: .omitted, time: .standard)
        entries.append("[\(t)] \(s)")
        if entries.count > 12 { entries.removeFirst() }
    }
}

struct Lesson15View: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var log = LifecycleLog()

    var body: some View {
        LessonScaffold(
            title: "15 — App Lifecycle",
            goal: "Observe scene phases and bridge to UIKit's UIApplicationDelegate when needed.",
            exercise: """
            1. Add an `@AppStorage("lastBackgroundedAt")` and store the timestamp on `.background`.
            2. Implement a `MyAppDelegate: NSObject, UIApplicationDelegate` and wire it via \
            `@UIApplicationDelegateAdaptor`. Log `application(_:didFinishLaunchingWithOptions:)`.
            3. Bonus: respond to `.onContinueUserActivity` for a Spotlight deep link.
            """
        ) {
            GroupBox("Current scene phase") {
                HStack {
                    Circle()
                        .fill(color(for: scenePhase))
                        .frame(width: 14, height: 14)
                    Text(label(for: scenePhase))
                        .font(.headline)
                }
            }

            GroupBox("Lifecycle log") {
                if log.entries.isEmpty {
                    Text("Background the app (Home/swipe up) to see transitions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(log.entries, id: \.self) { e in
                            Text(e).font(.caption.monospaced())
                        }
                    }
                }
            }
            .onChange(of: scenePhase, initial: true) { _, new in
                log.add("scenePhase → \(label(for: new))")
            }

            // Snippet only — wire-up belongs in @main App:
            //
            //   @main
            //   struct MyApp: App {
            //       @UIApplicationDelegateAdaptor(MyAppDelegate.self) var delegate
            //       var body: some Scene { WindowGroup { ContentView() } }
            //   }
            //
            //   final class MyAppDelegate: NSObject, UIApplicationDelegate {
            //       func application(_ app: UIApplication,
            //                        didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]?
            //                        ) -> Bool {
            //           // Firebase.configure(), push registration, etc.
            //           return true
            //       }
            //   }
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif

    private func label(for phase: ScenePhase) -> String {
        switch phase {
        case .active: "active"
        case .inactive: "inactive"
        case .background: "background"
        @unknown default: "unknown"
        }
    }

    private func color(for phase: ScenePhase) -> Color {
        switch phase {
        case .active: .green
        case .inactive: .yellow
        case .background: .red
        @unknown default: .gray
        }
    }
}

#Preview { NavigationStack { Lesson15View() } }

#if canImport(HotSwiftUI)
@_exported import HotSwiftUI
#elseif canImport(Inject)
@_exported import Inject
#else
// This code can be found in the Swift package:
// https://github.com/johnno1962/HotSwiftUI

#if DEBUG
import Combine

private var loadInjectionOnce: () = {
        guard objc_getClass("InjectionClient") == nil else {
            return
        }
        #if os(macOS) || targetEnvironment(macCatalyst)
        let bundleName = "macOSInjection.bundle"
        #elseif os(tvOS)
        let bundleName = "tvOSInjection.bundle"
        #elseif os(visionOS)
        let bundleName = "xrOSInjection.bundle"
        #elseif targetEnvironment(simulator)
        let bundleName = "iOSInjection.bundle"
        #else
        let bundleName = "maciOSInjection.bundle"
        #endif
        let bundlePath = "/Applications/InjectionIII.app/Contents/Resources/"+bundleName
        guard let bundle = Bundle(path: bundlePath), bundle.load() else {
            return print("""
                ⚠️ Could not load injection bundle from \(bundlePath). \
                Have you downloaded the InjectionIII.app from either \
                https://github.com/johnno1962/InjectionIII/releases \
                or the Mac App Store?
                """)
        }
}()

public let injectionObserver = InjectionObserver()

public class InjectionObserver: ObservableObject {
    @Published var injectionNumber = 0
    var cancellable: AnyCancellable? = nil
    let publisher = PassthroughSubject<Void, Never>()
    init() {
        _ = loadInjectionOnce // .enableInjection() optional Xcode 16+
        cancellable = NotificationCenter.default.publisher(for:
            Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { [weak self] change in
            self?.injectionNumber += 1
            self?.publisher.send()
        }
    }
}

extension SwiftUI.View {
    public func eraseToAnyView() -> some SwiftUI.View {
        _ = loadInjectionOnce
        return AnyView(self)
    }
    public func enableInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func loadInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
            .onReceive(injectionObserver.publisher, perform: bumpState)
            .eraseToAnyView()
    }
}

@available(iOS 13.0, *)
@propertyWrapper
public struct ObserveInjection: DynamicProperty {
    @ObservedObject private var iO = injectionObserver
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#else
extension SwiftUI.View {
    @inline(__always)
    public func eraseToAnyView() -> some SwiftUI.View { return self }
    @inline(__always)
    public func enableInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func loadInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
    }
}

@available(iOS 13.0, *)
@propertyWrapper
public struct ObserveInjection {
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#endif
#endif
