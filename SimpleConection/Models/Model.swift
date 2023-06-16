//
//  Model.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import Foundation
import CloudKit

var sampleContact = ContactStruct(
    name: "Зинаида",
    birthday: Date(),
    isFavorite: false,
    contact: EventStruct(
        distance: 3,
        component: Components.day,
        lastContact: Date(),
        reminder: true,
        allEvents: [
            Meeting(date: Date(timeIntervalSinceNow: 1038576.0), feeling: Feelings.veryGood, describe: "посидели в Метрополь кафе на последнем этаже. Классно пообщались, обсудили все темы"),
            Meeting(date: Date(timeIntervalSinceNow: 8330984.0), feeling: Feelings.notTooBad, describe: "поговорили по телефону, узнали что у друг друга нового, договорились в следующий раз попить кофе в Старбаксе на набережной")
        ]
    ), record: ViewModel().sampleData()!
)

struct ContactStruct: Identifiable, Codable, Equatable, Hashable {
    var id = UUID().uuidString
    var name: String
    var birthday: Date
    var isFavorite: Bool
    var contact: EventStruct
    var record: Data
    
    func updateInfo(name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, reminder: Bool) -> ContactStruct {
        return ContactStruct(name: name, birthday: birthday, isFavorite: isFavorite, contact: contact.updateInfo(distance: distance, component: component, reminder: reminder), record: record)
    }
    
    func updateWithoutEvent(name: String, birthday: Date, isFavorite: Bool) -> ContactStruct {
        return ContactStruct(name: name, birthday: birthday, isFavorite: isFavorite, contact: contact, record: record)
    }
    
    func changeLastContact(date: Date) -> ContactStruct {
        return ContactStruct(name: name, birthday: birthday, isFavorite: isFavorite, contact: contact.updateLastContact(lastContact: date), record: record)
    }
    
    func updateAndCreateEvent(name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, lastContact: Date, reminder: Bool, feeling: Feelings, describe: String) -> ContactStruct {
        let newContact = EventStruct(distance: distance, component: component, lastContact: lastContact, reminder: reminder, allEvents: [Meeting(date: lastContact, feeling: feeling, describe: describe)])
        return ContactStruct(name: name, birthday: birthday, isFavorite: isFavorite, contact: newContact, record: record)
    }
    
//    func updateInfoAndDeleteEvent(name: String, birthday: Date, isFavorite: Bool) -> ContactStruct {
//        return ContactStruct(name: name, birthday: birthday, isFavorite: isFavorite, contact: nil)
//    }
    
    func addMeeting(contact: EventStruct, date: Date, feeling: Feelings, describe: String) -> ContactStruct {
        let updatedContact = contact.addMeeting(date: date, feeling: feeling, describe: describe)
        return ContactStruct(name: name, birthday: birthday, isFavorite: isFavorite, contact: updatedContact, record: record)
    }
    
    func addRecord(metaData: Data) -> ContactStruct {
        return ContactStruct(id: id, name: name, birthday: birthday, isFavorite: isFavorite, contact: contact, record: metaData)
    }
}

struct EventStruct: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var distance: Int
    var component: Components
    var lastContact: Date
    var reminder: Bool
    var allEvents: [Meeting]
    
    func updateInfo(distance: Int, component: Components, reminder: Bool) -> EventStruct {
        return EventStruct(distance: distance, component: component, lastContact: lastContact, reminder: reminder, allEvents: allEvents)
    }
    
    func updateLastContact(lastContact: Date) -> EventStruct {
        return EventStruct(distance: distance, component: component, lastContact: lastContact, reminder: reminder, allEvents: allEvents)
    }
    
    func addMeeting(date: Date, feeling: Feelings, describe: String) -> EventStruct {
        let newMeeting = Meeting(date: date, feeling: feeling, describe: describe)
        var arr = allEvents
        arr.append(newMeeting)
        return EventStruct(distance: distance, component: component, lastContact: lastContact, reminder: reminder, allEvents: arr)
    }
    
    func getNextEventDate() -> Date {
        switch component {
        case .day:
            return Calendar.current.date(byAdding: Calendar.Component.day, value: distance, to: lastContact)!
        case .week:
            return Calendar.current.date(byAdding: Calendar.Component.day, value: (distance * 7), to: lastContact)!
        case .month:
            return Calendar.current.date(byAdding: Calendar.Component.month, value: distance, to: lastContact)!
        case .year:
            return Calendar.current.date(byAdding: Calendar.Component.year, value: distance, to: lastContact)!
        }
    }
}

struct Meeting: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var date: Date
    var feeling: Feelings
    var describe: String
    
    func updateMeeting(date: Date, feeling: Feelings, describe: String) -> Meeting {
        return Meeting(date: date, feeling: feeling, describe: describe)
    }
}

//struct DayStruct: Identifiable, Codable, Hashable {
//    var id = UUID()
//    let date: Date
//    let signs: [AnnualEnum: DayType]
//
//    var dateComponents: DateComponents {
//        var dateComponents = Calendar.current.dateComponents(
//            [.month,
//             .day,
//             .year],
//            from: date)
//        dateComponents.timeZone = TimeZone.current
//        dateComponents.calendar = Calendar(identifier: .gregorian)
//        return dateComponents
//    }
//}

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

enum FilterMainView: String, Codable, CaseIterable, Hashable {
    case standardOrder = "Без фильтра"
    case alphabeticalOrder = "По алфавиту"
    case dueDateOrder = "По дате общения"
    case favoritesOrder = "Избранные"
}
