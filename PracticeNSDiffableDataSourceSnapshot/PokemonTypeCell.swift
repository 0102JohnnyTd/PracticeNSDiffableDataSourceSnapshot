//
//  PokemonTypeCell.swift
//  PracticeNSDiffableDataSourceSnapshot
//
//  Created by Johnny Toda on 2023/02/25.
//

import UIKit

final class PokemonTypeCell: UICollectionViewCell {
    @IBOutlet private weak var typeLabel: UILabel!

    static let nib = UINib(nibName: String(describing: PokemonTypeCell.self), bundle: nil)
    // CellRegistrationを使用してCellの登録を実装した場合は不要
    static let identifier = String(describing: PokemonTypeCell.self)

    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? .systemGray5 : .systemBackground
        }
    }

    func configure(type: String?) {
        typeLabel.text = type
    }
}
