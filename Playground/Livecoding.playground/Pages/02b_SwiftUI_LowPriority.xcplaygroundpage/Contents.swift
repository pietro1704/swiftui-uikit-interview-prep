// Page 02b — SwiftUI Low-Priority drills
// Topics that rarely come up in LATAM senior livecoding interviews.
// Skim conceptually; only code if you have spare time after the high-priority page.

import SwiftUI
import PlaygroundSupport

PlaygroundPage.current.setLiveView(
    Text("Low-priority drills — see source")
        .frame(width: 360, height: 200)
)

// MARK: Drill A — Custom Layout — wrapping tag cloud  🔵 low
//
// Build a TagCloudLayout: Layout that wraps tags onto multiple rows when
// they don't fit horizontally.
//
// Talk-track (memorize this — much more likely than coding it):
// "Layout protocol gives sizeThatFits + placeSubviews. Walk subviews with
//  sv.sizeThatFits(.unspecified), maintain x/y/rowHeight cursor, wrap when
//  x + size.width > proposal.width. placeSubviews repeats the walk and
//  calls sv.place(at:proposal:)."

struct TagCloudLayout_Empty: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // TODO (only if you have time)
        .zero
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // TODO
    }
}

// MARK: Drill B — AnyLayout — adapt HStack/VStack  🔵 low
//
// Build a screen whose layout is HStack on regular size class and VStack
// on compact, switching dynamically — preserving subview identity.
//
// TODO: read @Environment(\.horizontalSizeClass).
// TODO: pick AnyLayout(HStackLayout()) vs AnyLayout(VStackLayout()).
// TODO: invoke as `layout { childA; childB }`.

struct PageBExerciseView: View {
    @Environment(\.horizontalSizeClass) var hSize
    var body: some View {
        // TODO
        Text("placeholder")
    }
}

/*
================================================================================
SOLUTIONS
================================================================================

// ----- Drill A -----
struct TagCloudLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// ----- Drill B -----
struct AdaptiveScreen: View {
    @Environment(\.horizontalSizeClass) var hSize
    var body: some View {
        let layout: AnyLayout = hSize == .regular
            ? AnyLayout(HStackLayout(spacing: 16))
            : AnyLayout(VStackLayout(spacing: 16))
        layout {
            Text("Sidebar")
            Text("Detail")
        }
    }
}

*/
