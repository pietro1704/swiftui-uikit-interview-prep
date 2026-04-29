import SwiftUI
import UIKit
import MapKit

// MARK: - Lesson 11 — UIKit ↔ SwiftUI Interop
//
// Three main bridges:
//  1. UIViewRepresentable             → embed a UIView inside SwiftUI
//  2. UIViewControllerRepresentable   → embed a UIViewController inside SwiftUI
//  3. UIHostingController             → embed a SwiftUI View inside UIKit
//
// The Coordinator is the piece that receives UIKit delegate callbacks
// (UITextField, MKMapView, etc.) and forwards them to SwiftUI.

// 1) UIView → SwiftUI: UITextField with toolbar (UIKit-only feature)
struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator,
                     action: #selector(Coordinator.editingChanged(_:)),
                     for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitTextField
        init(_ parent: UIKitTextField) { self.parent = parent }
        @objc func editingChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }
    }
}

// 2) UIViewController → SwiftUI: MKMapView via MKMapViewController genérico
struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5_000,
            longitudinalMeters: 5_000
        )
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        map.addAnnotation(pin)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}
}

// 3) SwiftUI inside UIKit (conceptual demo — not rendered, kept for reference)
//
// final class LegacyVC: UIViewController {
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         let host = UIHostingController(rootView: Lesson01View())
//         addChild(host)
//         host.view.translatesAutoresizingMaskIntoConstraints = false
//         view.addSubview(host.view)
//         NSLayoutConstraint.activate([
//             host.view.topAnchor.constraint(equalTo: view.topAnchor),
//             host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//             host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//             host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//         ])
//         host.didMove(toParent: self)
//     }
// }

struct Lesson11View: View {
    @State private var text = ""

    var body: some View {
        LessonScaffold(
            title: "11 — Interop UIKit",
            goal: "Embutir UIView/UIViewController em SwiftUI e vice-versa.",
            exercise: """
            1. Crie um wrapper para `UIPageViewController` (UIViewControllerRepresentable).
            2. Adicione `inputAccessoryView` no UIKitTextField com botão "Done" que chama resignFirstResponder.
            3. Bônus: crie um Coordinator que escuta `MKMapViewDelegate` e expõe `onRegionChange` callback.
            """
        ) {
            GroupBox("UITextField via UIViewRepresentable") {
                UIKitTextField(text: $text, placeholder: "Digite (UIKit por baixo)")
                    .frame(height: 36)
                Text("Bind: \(text)").font(.caption).foregroundStyle(.secondary)
            }

            GroupBox("MKMapView (UIKit)") {
                MapView(coordinate: .init(latitude: -23.5505, longitude: -46.6333))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview { NavigationStack { Lesson11View() } }
