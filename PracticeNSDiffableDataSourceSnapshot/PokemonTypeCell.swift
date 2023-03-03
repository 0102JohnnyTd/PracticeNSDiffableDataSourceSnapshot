//
//  PokemonTypeCell.swift
//  PracticeNSDiffableDataSourceSnapshot
//
//  Created by Johnny Toda on 2023/02/25.
//

import UIKit

class PokemonTypeCell: UICollectionViewCell {
    @IBOutlet private weak var typeLabel: UILabel!

    static let nib = UINib(nibName: String(describing: PokemonTypeCell.self), bundle: nil)
    static let identifier = String(describing: PokemonTypeCell.self)

    func configure(type: String?) {
        typeLabel.text = type
    }
}
