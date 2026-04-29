import SwiftUI

// MARK: - Lesson 16 — Accessibility
//
// Top topics interviewers ask:
//  - Dynamic Type (.font(.body) scales; avoid hardcoded sizes)
//  - VoiceOver labels / hints / values / traits
//  - Combining elements with .accessibilityElement(children:)
//  - Adjustable trait (custom value with up/down swipe)
//  - Reduce Motion / Reduce Transparency / Differentiate Without Color
//  - Color contrast and avoiding color as the *only* signal

struct Lesson16View: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rating = 3
    @State private var pulse = false

    var body: some View {
        LessonScaffold(
            title: "16 — Accessibility",
            goal: "Make the app usable with VoiceOver, large text, and motion sensitivity.",
            exercise: """
            1. Run the app with VoiceOver on (Settings → Accessibility) and audit the Stars row.
            2. Add `accessibilityHint("Double tap and swipe up/down to change")` to the rating control.
            3. Bonus: read `\\.legibilityWeight` and `\\.colorSchemeContrast`; bump font weight when contrast is increased.
            """
        ) {
            GroupBox("Combined element + adjustable trait") {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .foregroundStyle(i <= rating ? .yellow : .gray)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Rating")
                .accessibilityValue("\(rating) of 5 stars")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: rating = min(rating + 1, 5)
                    case .decrement: rating = max(rating - 1, 1)
                    @unknown default: break
                    }
                }
            }

            GroupBox("Dynamic Type — use semantic fonts") {
                Text("This text scales with the user's preferred size.")
                    .font(.body)              // ✅ scales
                Text("This one does NOT — bad for accessibility.")
                    .font(.system(size: 14))  // ❌ fixed size
                    .foregroundStyle(.secondary)
            }

            GroupBox("Reduce Motion aware animation") {
                Circle()
                    .fill(.blue)
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .animation(
                        reduceMotion ? .default : .easeInOut(duration: 0.6).repeatForever(),
                        value: pulse
                    )
                    .onAppear { pulse = true }
                Text(reduceMotion
                     ? "Reduce Motion is ON → animation is calm."
                     : "Toggle Reduce Motion in Accessibility settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GroupBox("Don't rely on color alone") {
                HStack {
                    Label("Success", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("Error", systemImage: "xmark.octagon.fill")
                        .foregroundStyle(.red)
                }
                .font(.callout)
                Text("Icons + text → still readable in greyscale or for color-blind users.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview { NavigationStack { Lesson16View() } }
