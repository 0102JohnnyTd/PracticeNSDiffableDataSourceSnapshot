//
//  Pokemon.swift
//  PracticeNSDiffableDataSourceSnapshot
//
//  Created by Johnny Toda on 2023/02/25.
//

import Foundation

// ポケモンのデータ構造
struct Pokemon: Decodable, Hashable {
    static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
        lhs.id == rhs.id
    }
    // ポケモンの名前
    let name: String
    // ポケモンの図鑑No.
    let id: Int
    // ポケモンの画像
    let sprites: Image
    // ポケモンのタイプ
    let types: [TypeEntry]
}

// 画像のデータ構造
struct Image: Decodable, Hashable {
    // ポケモンが正面向きの画像
    let frontImage: String

    // デコードの際の代替キーをfrontImageプロパティにセット
    enum CodingKeys: String, CodingKey {
        case frontImage = "front_default"
    }
}

// ポケモンのタイプ
struct TypeEntry: Decodable, Hashable {
    let type: Mode
}

// "Type"が命名で利用できず、他に適切な表現が思い浮かばなかった。
struct Mode: Decodable, Hashable {
    let name: String
}
