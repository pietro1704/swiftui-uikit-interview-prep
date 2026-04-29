# 🛠 UIKit Cheat Sheet

## UIViewController lifecycle

```
init → loadView → viewDidLoad (once)
       ↓
viewWillAppear → viewIsAppearing (iOS 13+) → viewDidAppear
       ↓
viewWillLayoutSubviews → viewDidLayoutSubviews   (every layout pass)
       ↓
viewWillDisappear → viewDidDisappear
       ↓
deinit
```

## Auto Layout in code

```swift
let label = UILabel()
label.translatesAutoresizingMaskIntoConstraints = false  // ALWAYS
view.addSubview(label)
NSLayoutConstraint.activate([
    label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
])
```

**Hugging** (resistance to growing) and **Compression Resistance** (resistance to shrinking):

```swift
label.setContentHuggingPriority(.required, for: .horizontal)
label.setContentCompressionResistancePriority(.required, for: .horizontal)
```

## UICollectionView Diffable + Compositional

```swift
// 1. Layout
let layout = UICollectionViewCompositionalLayout { _, _ in
    let item = NSCollectionLayoutItem(layoutSize: .init(
        widthDimension: .fractionalWidth(1/3),
        heightDimension: .fractionalHeight(1)))
    let group = NSCollectionLayoutGroup.horizontal(
        layoutSize: .init(widthDimension: .fractionalWidth(1),
                           heightDimension: .absolute(100)),
        subitems: [item])
    return NSCollectionLayoutSection(group: group)
}

// 2. Cell registration (iOS 14+)
let cellReg = UICollectionView.CellRegistration<MyCell, Item> { cell, _, item in
    cell.configure(with: item)
}

// 3. Diffable Data Source
let ds = UICollectionViewDiffableDataSource<Section, Item>(collectionView: cv) {
    cv, idx, item in
    cv.dequeueConfiguredReusableCell(using: cellReg, for: idx, item: item)
}

// 4. Snapshot
var snap = NSDiffableDataSourceSnapshot<Section, Item>()
snap.appendSections([.main])
snap.appendItems(items)
ds.apply(snap, animatingDifferences: true)
```

## Custom UIControl

```swift
final class MyControl: UIControl {
    var value: Int = 0 {
        didSet { sendActions(for: .valueChanged) }
    }
}

let c = MyControl()
c.addAction(UIAction { _ in print("changed!") }, for: .valueChanged)
```

## UIKit animations

```swift
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 0
} completion: { _ in ... }

// Spring (legacy)
UIView.animate(withDuration: 0.5, delay: 0,
               usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) { ... }

// Modern (iOS 17+)
UIView.animate(.spring(duration: 0.4)) { ... }
```

## Avoiding retain cycles

```swift
networkClient.fetch { [weak self] result in     // ✅
    guard let self else { return }
    self.handle(result)
}
```
