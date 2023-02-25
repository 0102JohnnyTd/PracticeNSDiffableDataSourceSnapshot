//
//  PokemonCell.swift
//  SampleUICollectionViewDiffableDataSource
//
//  Created by Johnny Toda on 2023/02/01.
//

import UIKit
import Kingfisher

final class PokemonCell: UICollectionViewCell {
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    static let nib = UINib(nibName: String(describing: PokemonCell.self), bundle: nil)
    static let identifier = String(describing: PokemonCell.self)

    func configure(imageURL: String, name: String) {
        iconView.kf.setImage(with: URL(string: imageURL))
        nameLabel.text = name
    }
}
