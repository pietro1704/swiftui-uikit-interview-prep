import SwiftUI
import UIKit

// MARK: - Lesson 12 — Advanced UIKit (interview review)
//
// Topics covered:
//  - UIViewController lifecycle
//  - Programmatic Auto Layout with NSLayoutConstraint
//  - UICollectionView Compositional Layout + Diffable Data Source
//  - Custom UIControl using sendActions

// =====================================================================
// MARK: ViewController lifecycle (cheat sheet — handy for theory questions)
// =====================================================================
//
//   init(coder/nibName) → loadView → viewDidLoad (once)
//   viewWillAppear → viewIsAppearing (iOS 13+) → viewDidAppear
//   viewWillLayoutSubviews → viewDidLayoutSubviews (each layout pass)
//   viewWillDisappear → viewDidDisappear
//   deinit (watch for retain cycles in closures: [weak self])

// =====================================================================
// MARK: UICollectionView with Compositional + Diffable
// =====================================================================

final class GridViewController: UIViewController {

    enum Section { case main }
    struct Item: Hashable { let id = UUID(); let color: UIColor; let title: String }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureCollectionView()
        configureDataSource()
        applyInitialSnapshot()
    }

    private func configureCollectionView() {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1/3),
                heightDimension: .fractionalHeight(1)))
            item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .fractionalWidth(1),
                                   heightDimension: .absolute(100)),
                subitems: [item])

            return NSCollectionLayoutSection(group: group)
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, _, item in
            cell.contentView.backgroundColor = item.color
            cell.contentView.layer.cornerRadius = 8
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            let label = UILabel()
            label.text = item.title
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 14)
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
        }

        dataSource = .init(collectionView: collectionView) { cv, idx, item in
            cv.dequeueConfiguredReusableCell(using: cellRegistration, for: idx, item: item)
        }
    }

    private func applyInitialSnapshot() {
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange,
                                  .systemPurple, .systemTeal, .systemPink, .systemIndigo, .systemYellow]
        let items = colors.enumerated().map { Item(color: $0.element, title: "Cell \($0.offset+1)") }

        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections([.main])
        snap.appendItems(items)
        dataSource.apply(snap, animatingDifferences: false)
    }
}

// =====================================================================
// MARK: Custom UIControl (rating stars)
// =====================================================================

final class RatingControl: UIControl {
    var rating: Int = 0 { didSet { updateUI(); sendActions(for: .valueChanged) } }
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame); setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        stack.axis = .horizontal
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        for i in 0..<5 {
            let btn = UIButton(type: .system)
            btn.tag = i + 1
            btn.setImage(UIImage(systemName: "star"), for: .normal)
            btn.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }
    }

    @objc private func tap(_ sender: UIButton) { rating = sender.tag }

    private func updateUI() {
        for case let btn as UIButton in stack.arrangedSubviews {
            let filled = btn.tag <= rating
            btn.setImage(UIImage(systemName: filled ? "star.fill" : "star"), for: .normal)
        }
    }
}

// Wrappers SwiftUI para mostrar
private struct GridVCWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GridViewController { GridViewController() }
    func updateUIViewController(_ uiViewController: GridViewController, context: Context) {}
}

private struct RatingControlWrapper: UIViewRepresentable {
    @Binding var rating: Int
    func makeUIView(context: Context) -> RatingControl {
        let c = RatingControl()
        c.addAction(UIAction { [weak c] _ in
            guard let c else { return }
            rating = c.rating
        }, for: .valueChanged)
        return c
    }
    func updateUIView(_ uiView: RatingControl, context: Context) {
        if uiView.rating != rating { uiView.rating = rating }
    }
}

struct Lesson12View: View {
    @State private var rating = 0

    var body: some View {
        LessonScaffold(
            title: "12 — Advanced UIKit",
            goal: "Compositional Layout, Diffable Data Source, Auto Layout, Custom UIControl.",
            exercise: """
            1. Adicione header suplementar à compositional section (NSCollectionLayoutBoundarySupplementaryItem).
            2. Implemente UICollectionViewDelegate e mostre alerta ao tocar uma célula.
            3. Bônus: faça RatingControl conformar a UIAccessibilityTraits.adjustable (acessibilidade).
            """
        ) {
            GroupBox("UICollectionView (Compositional + Diffable)") {
                GridVCWrapper().frame(height: 320)
            }

            GroupBox("Custom UIControl — rating: \(rating)") {
                RatingControlWrapper(rating: $rating).frame(height: 44)
            }
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview { NavigationStack { Lesson12View() } }
