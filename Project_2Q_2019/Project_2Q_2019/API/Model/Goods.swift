//
//  Goods.swift
//  Project_2Q_2019
//
//  Created by JUNHYEOK KWON on 2020/02/08.
//  Copyright © 2020 JUNHYEOK KWON. All rights reserved.
//

import Foundation

struct Goods: Codable {
    var name: String
    var category: String
    var id: String
    var time: String
}

struct BoughtGoods: Codable {
    var id: String
    var boughtDate: String
    var year: String
    var yearMonth: String
    var category: String
    var name: String
    var amount: Int
    var price: Int
    var time: String
}

struct DateCount: Codable {
    var date: String
    var count: Int
}

extension Array where Element == BoughtGoods {

    var food: [Element] { filter(for: .food) }

    var household: [Element] { filter(for: .household) }

    var clothes: [Element] { filter(for: .clothes) }

    var miscellaneous: [Element] { filter(for: .miscellaneous) }

    var totalPrice: Double { reduce(0) { $0 + Double($1.price * $1.amount) } }

    private func filter(for category: GoodsCategory) -> [Element] {
        filter { $0.category == category.key }
    }
}

extension Goods {

    static func from(_ boughtGoods: BoughtGoods) -> Self {
        .init(name: boughtGoods.name, category: boughtGoods.category, id: boughtGoods.id, time: Date().toString(format: DateType.firebase_key_fulldate))
    }
}
