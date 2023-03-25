//
//  PokemonDetailViewController.swift
//  PracticeNSDiffableDataSourceSnapshot
//
//  Created by Johnny Toda on 2023/03/22.
//

import UIKit
import Kingfisher

class PokemonDetailViewController: UIViewController {
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    var pokemon: Pokemon?

    // インスタンス生成時のハードコーディング対策
    static let storyboardName = "PokemonDetail"
    static let idenfitifier = "PokemonDetail"

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    private func configure() {
        guard let pokemon = pokemon else { fatalError("unexpected error") }
        iconView.kf.setImage(with: URL(string: pokemon.sprites.frontImage))
        nameLabel.text = pokemon.name 
    }
}
