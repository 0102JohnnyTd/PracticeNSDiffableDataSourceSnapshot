//
//  ViewController.swift
//  PracticeNSDiffableDataSourceSnapshot
//
//  Created by Johnny Toda on 2023/02/25.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!

    enum Section: Int, Hashable, CaseIterable, CustomStringConvertible {
        case pokemonTypes, pokemonList

        var description: String {
            switch self {
            case .pokemonTypes: return "PokemonTypes"
            case .pokemonList: return "PokemonList"
            }
        }
    }

    struct Item: Hashable {
        let pokemonType: String?
        let pokemon: Pokemon?
        init(pokemon: Pokemon? = nil, pokemonType: String? = nil) {
            self.pokemon = pokemon
            self.pokemonType = pokemonType
        }
        private let identifier = UUID()
    }

    // ポケモンのタイプをまとめるSetを定義
    var pokemonTypes = Set<Item>()

    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavItem()
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()
    }
}

extension ViewController {
    func configureNavItem() {
        navigationItem.title = "Emoji Explorer"
        navigationItem.largeTitleDisplayMode = .always
    }

    func configureHierarchy() {
        collectionView.collectionViewLayout = createLayout()
        collectionView.delegate = self
        collectionView.register(PokemonTypeCell.nib, forCellWithReuseIdentifier: PokemonTypeCell.identifier)
        collectionView.register(PokemonCell.nib, forCellWithReuseIdentifier: PokemonCell.identifier)
    }

    /// - Tag: CreateFullLayout
    func createLayout() -> UICollectionViewLayout {

        let sectionProvider = { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            guard let sectionKind = Section(rawValue: sectionIndex) else { return nil }

            let section: NSCollectionLayoutSection

            // orthogonal scrolling section of images
            if sectionKind == .pokemonTypes {

                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.28), heightDimension: .fractionalWidth(0.2))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

            // outline
            } else if sectionKind == .pokemonList {
                section = NSCollectionLayoutSection.list(using: .init(appearance: .sidebar), layoutEnvironment: layoutEnvironment)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10)

            // list
//            } else if sectionKind == .list {
//                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
//                configuration.leadingSwipeActionsConfigurationProvider = { [weak self] (indexPath) in
//                    guard let self = self else { return nil }
//                    guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
//                    return self.leadingSwipeActionConfigurationForListCellItem(item)
//                }
//                section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            } else {
                fatalError("Unknown section!")
            }

            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
            if let coordinator = self.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }) { (context) in
                    if context.isCancelled {
                        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            } else {
                self.collectionView.deselectItem(at: indexPath, animated: animated)
            }
        }
    }

    func accessoriesForListCellItem(_ item: Item) -> [UICellAccessory] {
        // itemが何かわからん
        let isStarred = self.pokemonTypes.contains(item)
        var accessories = [UICellAccessory.disclosureIndicator()]
        if isStarred {
            let star = UIImageView(image: UIImage(systemName: "star.fill"))
            accessories.append(.customView(configuration: .init(customView: star, placement: .trailing())))
        }
        return accessories
    }

    func leadingSwipeActionConfigurationForListCellItem(_ item: Item) -> UISwipeActionsConfiguration? {
        let isStarred = self.pokemonTypes.contains(item)
        let starAction = UIContextualAction(style: .normal, title: nil) {
            [weak self] (_, _, completion) in
            guard let self = self else {
                completion(false)
                return
            }

            // Don't check again for the starred state. We promised in the UI what this action will do.
            // If the starred state has changed by now, we do nothing, as the set will not change.
            if isStarred {
                self.pokemonTypes.remove(item)
            } else {
                self.pokemonTypes.insert(item)
            }

            // Reconfigure the cell of this item
            // Make sure we get the current index path of the item.
            if let currentIndexPath = self.dataSource.indexPath(for: item) {
                if let cell = self.collectionView.cellForItem(at: currentIndexPath) as? UICollectionViewListCell {
                    UIView.animate(withDuration: 0.2) {
                        cell.accessories = self.accessoriesForListCellItem(item)
                    }
                }
            }

            completion(true)
        }
        starAction.image = UIImage(systemName: isStarred ? "star.slash" : "star.fill")
        starAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [starAction])
    }

//    func createGridCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, Emoji> {
//        return UICollectionView.CellRegistration<UICollectionViewCell, Emoji> { (cell, indexPath, emoji) in
//            var content = UIListContentConfiguration.cell()
//            content.text = emoji.text
//            content.textProperties.font = .boldSystemFont(ofSize: 38)
//            content.textProperties.alignment = .center
//            content.directionalLayoutMargins = .zero
//            cell.contentConfiguration = content
//            var background = UIBackgroundConfiguration.listPlainCell()
//            background.cornerRadius = 8
//            background.strokeColor = .systemGray3
//            background.strokeWidth = 1.0 / cell.traitCollection.displayScale
//            cell.backgroundConfiguration = background
//        }
//    }

//    func createOutlineHeaderCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, String> {
//        return UICollectionView.CellRegistration<UICollectionViewListCell, String> { (cell, indexPath, title) in
//            var content = cell.defaultContentConfiguration()
//            content.text = title
//            cell.contentConfiguration = content
//            cell.accessories = [.outlineDisclosure(options: .init(style: .header))]
//        }
//    }

//    func createOutlineCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Emoji> {
//        return UICollectionView.CellRegistration<UICollectionViewListCell, Emoji> { (cell, indexPath, emoji) in
//            var content = cell.defaultContentConfiguration()
//            content.text = emoji.text
//            content.secondaryText = emoji.title
//            cell.contentConfiguration = content
//            cell.accessories = [.disclosureIndicator()]
//        }
//    }

    /// - Tag: ConfigureListCell
//    func createListCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
//        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] (cell, indexPath, item) in
//            guard let self = self, let emoji = item.emoji else { return }
//            var content = UIListContentConfiguration.valueCell()
//            content.text = emoji.text
//            content.secondaryText = String(describing: emoji.category)
//            cell.contentConfiguration = content
//            cell.accessories = self.accessoriesForListCellItem(item)
//        }
//    }

    /// - Tag: DequeueCells
    func configureDataSource() {
        // create registrations up front, then choose the appropriate one to use in the cell provider
//        let gridCellRegistration = createGridCellRegistration()
//        let listCellRegistration = createListCellRegistration()
//        let outlineHeaderCellRegistration = createOutlineHeaderCellRegistration()
//        let outlineCellRegistration = createOutlineCellRegistration()

        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            guard let section = Section(rawValue: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .pokemonTypes:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokemonTypeCell.identifier, for: indexPath) as! PokemonTypeCell
                return cell
//                cell.configure(type: <#T##String#>)
            case .pokemonList:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokemonCell.identifier, for: indexPath) as! PokemonCell
                return cell
            }
        }
    }

    /// - Tag: SectionSnapshot
    func applyInitialSnapshots() {

        // set the order for our sections

        let sections = Section.allCases
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)

        // recents (orthogonal scroller)

        // 🍏recentsSnapshotに追加するItem。ここにPokemonTypeを置き換えれば良い。
        let pokemonTypeItems = Emoji.Category.recents.emojis.map { Item(emoji: $0) }
        var pokemonTypeSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
//        recentsSnapshot.append(recentItems)
        pokemonTypeSnapshot.append(pokemonTypeItems)
        // 🍎278行目あたりにも同じコードがある。なんで2回追加する必要があるのか？
        dataSource.apply(pokemonTypeSnapshot, to: .pokemonTypes, animatingDifferences: false)

        // list of all + outlines

        // 🍎Itemの型を例えばInt型とかに変えたらエラー起きる？apply先のDataSourceの型に従わないとコンパイルエラーが出ると予想。
//        var allSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()

        var pokemonListSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()

        for category in Emoji.Category.allCases where category != .recents {
            // append to the "all items" snapshot
            let allSnapshotItems = category.emojis.map { Item(emoji: $0) }
            allSnapshot.append(allSnapshotItems)

            // setup our parent/child relations
            let pokemonListItem = Item(title: String(describing: category), hasChildren: true)
            pokemonListSnapshot.append(pokemonListItem)
//            let outlineItems = category.emojis.map { Item(emoji: $0) }
//            outlineSnapshot.append(outlineItems, to: rootItem)
        }
        dataSource.apply(pokemonTypeSnapshot, to: .pokemonTypes, animatingDifferences: false)
        dataSource.apply(pokemonListSnapshot, to: .pokemonList, animatingDifferences: false)
//        dataSource.apply(outlineSnapshot, to: .outline, animatingDifferences: false)

        // prepopulate starred emojis

//        for _ in 0..<5 {
//            if let item = allSnapshot.items.randomElement() {
//                self.starredEmojis.insert(item)
//            }
//        }
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // なんでself?
        guard let emoji = self.dataSource.itemIdentifier(for: indexPath)?.emoji else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        let detailViewController = EmojiDetailViewController(with: emoji)
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
}
