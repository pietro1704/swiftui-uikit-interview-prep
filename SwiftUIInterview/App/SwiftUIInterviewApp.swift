import SwiftUI
import SwiftData

@main
struct SwiftUIInterviewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TaskItem.self])
    }
}
