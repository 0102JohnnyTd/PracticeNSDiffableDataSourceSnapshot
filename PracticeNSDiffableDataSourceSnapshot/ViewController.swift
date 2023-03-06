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
        case pokemonTypeList, pokemonList

        var description: String {
            switch self {
            case .pokemonTypeList: return "PokemonTypes"
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

    private let api = API()

    // パースしたデータを格納する配列
    private var pokemons: [Item] = []
    // ポケモンのタイプをまとめるSet
//    private var pokemonTypes = Set<Item>()
    private var pokemonTypes = Set<String>()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
        configureNavItem()
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()
    }
}

extension ViewController {
    private func showErrorAlertController() {
        let alertController = UIAlertController(title: "エラー", message: "通信エラーが発生しました", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}


extension ViewController {
//    private func fetchData(completion: @escaping ([Item]?) -> Void) { もしかしたら必要かも。
    private func fetchData() {
        api.decodePokemonData(completion: { [weak self] result in
            switch result {
            case .success(let pokemonsData):
                pokemonsData.forEach {
                    self?.pokemons.append(Item(pokemon: $0))
                }
                // 図鑑順に並び替え
                self?.pokemons.sort { $0.pokemon?.id ?? 0 < $1.pokemon?.id ?? 0 }

//                pokemons.sort { $0.id < $1.id }
                print("pokemonsの中身:", self?.pokemons)
                self?.pokemons.forEach { item in
                    item.pokemon?.types.forEach { self?.pokemonTypes.insert($0.type.name) }
                }
                print("pokemonTypesの要素の数：", self?.pokemonTypes.count)
//                print("pokemonTypesの中身:", self?.pokemonTypes)
                DispatchQueue.main.async {
                    self?.configureDataSource()
                }
            case .failure:
                self?.showErrorAlertController()
            }
        })
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
            if sectionKind == .pokemonTypeList {
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

//    func accessoriesForListCellItem(_ item: Item) -> [UICellAccessory] {
//        // itemが何かわからん
//        let isStarred = self.pokemonTypes.contains(item)
//        var accessories = [UICellAccessory.disclosureIndicator()]
//        if isStarred {
//            let star = UIImageView(image: UIImage(systemName: "star.fill"))
//            accessories.append(.customView(configuration: .init(customView: star, placement: .trailing())))
//        }
//        return accessories
//    }

//    func leadingSwipeActionConfigurationForListCellItem(_ item: Item) -> UISwipeActionsConfiguration? {
//        let isStarred = self.pokemonTypes.contains(item)
//        let starAction = UIContextualAction(style: .normal, title: nil) {
//            [weak self] (_, _, completion) in
//            guard let self = self else {
//                completion(false)
//                return
//            }
//
//            // Don't check again for the starred state. We promised in the UI what this action will do.
//            // If the starred state has changed by now, we do nothing, as the set will not change.
//            if isStarred {
//                self.pokemonTypes.remove(item)
//            } else {
//                self.pokemonTypes.insert(item)
//            }
//
//            // Reconfigure the cell of this item
//            // Make sure we get the current index path of the item.
//            if let currentIndexPath = self.dataSource.indexPath(for: item) {
//                if let cell = self.collectionView.cellForItem(at: currentIndexPath) as? UICollectionViewListCell {
//                    UIView.animate(withDuration: 0.2) {
//                        cell.accessories = self.accessoriesForListCellItem(item)
//                    }
//                }
//            }
//
//            completion(true)
//        }
//        starAction.image = UIImage(systemName: isStarred ? "star.slash" : "star.fill")
//        starAction.backgroundColor = .systemBlue
//        return UISwipeActionsConfiguration(actions: [starAction])
//    }

    /// - Tag: DequeueCells
    func configureDataSource() {
        // create registrations up front, then choose the appropriate one to use in the cell provider
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            guard let section = Section(rawValue: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .pokemonTypeList:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokemonTypeCell.identifier, for: indexPath) as! PokemonTypeCell

                self?.pokemonTypes.forEach {
                    cell.configure(type: $0)
                }
                return cell
            case .pokemonList:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokemonCell.identifier, for: indexPath) as! PokemonCell
                cell.configure(imageURL: self?.pokemons[indexPath.row].pokemon?.sprites.frontImage, name: self?.pokemons[indexPath.row].pokemon?.name)
                return cell
            }
        }
        applyInitialSnapshots()
    }

    /// - Tag: SectionSnapshot
    func applyInitialSnapshots() {

        // set the order for our sections
        let sections = Section.allCases
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)

        // pokemonTypes (orthogonal scroller)
        let pokemonTypeItems = pokemonTypes.map { Item(pokemonType: $0) }
        var pokemonTypeSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        pokemonTypeSnapshot.append(pokemonTypeItems)
        print("pokemonTypeSnapshot:", pokemonTypeSnapshot.items)
        // 🍎278行目あたりにも同じコードがある。なんで2回追加する必要があるのか？
        dataSource.apply(pokemonTypeSnapshot, to: .pokemonTypeList, animatingDifferences: false)

        // pokemonList
        var pokemonListSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        pokemonListSnapshot.append(pokemons)
        print("pokemonListSnapshot:", pokemonListSnapshot.items)
        dataSource.apply(pokemonListSnapshot, to: .pokemonList, animatingDifferences: false)


        print("apply後のpokemonTypeSnapshot:", pokemonTypeSnapshot.items)
        print("apply後のpokemonListSnapshot:", pokemonListSnapshot.items)
        dataSource.apply(pokemonTypeSnapshot, to: .pokemonTypeList, animatingDifferences: false)
        dataSource.apply(pokemonListSnapshot, to: .pokemonList, animatingDifferences: false)
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        // 各PokemonのDetailsViewControllerに遷移する
//        guard let emoji = self.dataSource.itemIdentifier(for: indexPath)?.emoji else {
//            collectionView.deselectItem(at: indexPath, animated: true)
//            return
//        }
//        let detailViewController = EmojiDetailViewController(with: emoji)
//        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
}
