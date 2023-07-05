//
//  Model.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import Foundation

struct DayType: Codable, Hashable, Identifiable {
    var id = UUID()
    let title: String
    let emoji: String
    let text: String?
}

enum Components: String, Codable, CaseIterable, Hashable {
    case day = "день"
    case week = "неделя"
    case month = "месяц"
    case year = "год"
}

enum Feelings: String, Codable, CaseIterable, Hashable {
    case veryBad = "😡"
    case bad = "🙁"
    case notTooBad = "🤔"
    case good = "🙂"
    case veryGood = "😀"
}

enum ContactsOrder: String, Codable, CaseIterable, Hashable {
    case alphabetical = "A-Z"
    case backwards = "Z-A"
    case dueDate = "Due date"
    case favorites = "Favorites"
}
