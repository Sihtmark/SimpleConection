//
//  ViewModel.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI
import EventKit
import CloudKit

class ViewModel: ObservableObject {
    
    let nm = NotificationManager()
    
    @Published var isSignedIntoiCloud = false
    @Published var error = ""
    @Published var userName = ""
    @Published var email = ""
    @Published var telephone = ""
    @Published var permissionStatus = false
    @Published var contacts = [ContactStruct]() {
        didSet {
            saveContacts()
        }
    }
    
    let contactsKey = "items_list"
    
    init() {
        fetchContacts()
        requestPermission()
        getiCloudStatus()
        fetchiCloudUserRecordID()
    }
    
    func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] returnedStatus, returnedError in
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    self?.error = CloudKitError.iCloudAccountNotDetermined.rawValue
                case .available:
                    self?.isSignedIntoiCloud = true
                case .restricted:
                    self?.error = CloudKitError.iCloudAccountRestricted.rawValue
                case .noAccount:
                    self?.error = CloudKitError.iCloudAccountNotFound.rawValue
                case .temporarilyUnavailable:
                    self?.error = CloudKitError.iCloudAccountTemporarilyUnavailable.rawValue
                @unknown default:
                    self?.error = CloudKitError.iCloudAccountUnknown.rawValue
                }
            }
        }
    }
    
    func discoveriCloudUser(id: CKRecord.ID) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] returnedIdentity, returnedError in
            DispatchQueue.main.async {
                
                if let name = returnedIdentity?.nameComponents?.familyName {
                    self?.userName = name
                }
                
                // We can't get email because we get permission by id. We can get email if we get permission by email
                if let email = returnedIdentity?.lookupInfo?.emailAddress {
                    self?.email = email
                }
                
                // We can't get number because we get permission by id. We can get number if we get permission by number
                if let phone = returnedIdentity?.lookupInfo?.phoneNumber {
                    self?.telephone = phone
                }
            }
        }
    }
    
    func fetchiCloudUserRecordID() {
        CKContainer.default().fetchUserRecordID { [weak self] returnedID, returnedError in
            if let id = returnedID {
                self?.discoveriCloudUser(id: id)
            }
        }
    }
    
    func requestPermission() {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
            DispatchQueue.main.async {
                if returnedStatus == .granted {
                    self?.permissionStatus = true
                }
            }
        }
    }
    
    func fetchContacts() {
        guard let data = UserDefaults.standard.data(forKey: contactsKey), let savedItems = try? JSONDecoder().decode([ContactStruct].self, from: data) else {return}
        self.contacts = savedItems
    }
    
    func saveContacts() {
        if let encodedData = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(encodedData, forKey: contactsKey)
        }
    }
    
    func createNewContact(name: String, birthday: Date, distance: Int, component: Components, lastContact: Date, reminder: Bool, meetingTracker: Bool, feeling: Feelings, describe: String, isFavorite: Bool) {
        
        let newContact = EventStruct(
            distance: distance,
            component: component,
            lastContact: lastContact,
            reminder: reminder,
            allEvents: [ Meeting(
                date: lastContact,
                feeling: feeling,
                describe: describe)
            ]
        )
        
        let newCustomer = ContactStruct(
            name: name,
            birthday: birthday,
            isFavorite: isFavorite,
            contact: meetingTracker ? newContact : nil
        )
        
        if meetingTracker && reminder {
            setNotification(contactStruct: newCustomer)
        }
        contacts.append(newCustomer)
    }
    
    func updateContact(client: ContactStruct, name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, lastContact: Date, reminder: Bool, meetingTracker: Bool, feeling: Feelings, describe: String) {
        if let index = contacts.firstIndex(where: {$0.id == client.id}) {
            if meetingTracker {
                if client.contact != nil {
                    contacts[index] = client.updateInfo(name: name, birthday: birthday, isFavorite: isFavorite, distance: distance, component: component, reminder: reminder)
                    saveContacts()
                } else {
                    contacts[index] = client.updateAndCreateEvent(name: name, birthday: birthday, isFavorite: isFavorite, distance: distance, component: component, lastContact: lastContact, reminder: reminder, feeling: feeling, describe: describe)
                    saveContacts()
                }
            } else {
                if client.contact != nil {
                    contacts[index] = client.updateInfoAndDeleteEvent(name: name, birthday: birthday, isFavorite: isFavorite)
                } else {
                    contacts[index] = client.updateWithoutEvent(name: name, birthday: birthday, isFavorite: isFavorite)
                }
            }
        }
        fetchContacts()
    }
    
    func updateEvent(contact: ContactStruct) {
        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
            contacts[index] = contact.changeLastContact(date: Date())
        }
    }
    
    func deleteContact(indexSet: IndexSet) {
        contacts.remove(atOffsets: indexSet)
    }
    
    func moveContact(from: IndexSet, to: Int) {
        contacts.move(fromOffsets: from, toOffset: to)
    }
    
    func extractDate(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = format
        
        return formatter.string(from: date)
    }
    
    func isToday(date: Date, pickedDate: Date) -> Bool {
        
        let calendar = Calendar.current
        
        return calendar.isDate(pickedDate, inSameDayAs: date)
    }
    
    func getNextEventDate(component: Components, lastContact: Date, interval: Int) -> Date {
        switch component {
        case .day:
            return Calendar.current.date(byAdding: Calendar.Component.day, value: interval, to: lastContact)!
        case .week:
            return Calendar.current.date(byAdding: Calendar.Component.day, value: (interval * 7), to: lastContact)!
        case .month:
            return Calendar.current.date(byAdding: Calendar.Component.month, value: interval, to: lastContact)!
        case .year:
            return Calendar.current.date(byAdding: Calendar.Component.year, value: interval, to: lastContact)!
        }
    }
    
    func daysFromLastEvent(lastEvent: Date) -> String {
        let calendar = Calendar.current
        let distance = calendar.dateComponents([.day], from: lastEvent, to: Date())
        let days = distance.day!
        var dayReminder: Int {
            if days < 20 {
                return days
            } else if days % 1000 >= 1 {
                return days % 1000
            } else if days % 100 >= 1 {
                return days % 100
            } else {
                return days % 10
            }
        }
        switch dayReminder {
        case 1:
            return "Прошел \(days) день"
        case 2...4:
            return "Прошло \(days) дня"
        case 11...19:
            return "Прошло \(days) дней"
        default:
            return "Прошло \(days) дней"
        }
    }
    
    func daysFromLastEventCell(lastEvent: Date) -> String {
        let calendar = Calendar.current
        let distance = calendar.dateComponents([.day], from: lastEvent, to: Date())
        let days = distance.day!
        var dayReminder: Int {
            if days < 20 {
                return days
            } else {
                return days % 10
            }
        }
        switch dayReminder {
        case 1:
            return "\(days) день"
        case 2...4:
            return "\(days) дня"
        case 11...19:
            return "\(days) дней"
        default:
            return "\(days) дней"
        }
    }
    
    func updateMeeting(contact: ContactStruct, meeting: Meeting, date: Date, feeling: Feelings, describe: String) {
        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
            if let i = contacts[index].contact!.allEvents.firstIndex(where: {$0.id == meeting.id}) {
                contacts[index].contact!.allEvents[i].date = date
                contacts[index].contact!.allEvents[i].feeling = feeling
                contacts[index].contact!.allEvents[i].describe = describe
            }
        }
    }
    
    func deleteMeeting(contact: ContactStruct, meeting: Meeting) {
        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
            if let i = contacts[index].contact!.allEvents.firstIndex(where: {$0.id == meeting.id}) {
                contacts[index].contact!.allEvents.remove(at: i)
            }
        }
    }
    
    func toggleFavorite(contact: ContactStruct) {
        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
            contacts[index].isFavorite.toggle()
        }
    }
    
    func addMeeting(contact: ContactStruct, date: Date, feeling: Feelings, describe: String) {
        let newMeeting = Meeting(date: date, feeling: feeling, describe: describe)
        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
            contacts[index].contact!.allEvents.append(newMeeting)
            contacts[index].contact!.lastContact = contacts[index].contact!.lastContact < date ? date : contacts[index].contact!.lastContact
            if contacts[index].contact!.reminder {
                setNotification(contactStruct: contacts[index])
            }
        }
    }
    
    func listOrder(order: FilterMainView) -> [ContactStruct] {
        switch order {
        case .standardOrder:
            return contacts
        case .alphabeticalOrder:
            return contacts.sorted(by: {$0.name > $1.name})
        case .dueDateOrder:
            return contacts.filter{$0.contact != nil}.sorted(by: {$0.contact!.getNextEventDate() < $1.contact!.getNextEventDate()})
        case .favoritesOrder:
            return contacts.filter{$0.isFavorite}
        case .withoutTracker:
            return contacts.filter{$0.contact == nil}
        }
    }
    
    func deleteNotification(contactStruct: ContactStruct) {
        nm.cancelNotification(id: contactStruct.id)
    }
    
    func setNotification(contactStruct: ContactStruct) {
        nm.cancelNotification(id: contactStruct.id)
        if let contact = contactStruct.contact {
            let date = getNextEventDate(component: contact.component, lastContact: contact.lastContact, interval: contact.distance)
            let calendar = Calendar.current
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            nm.scheduleNotification(contact: contactStruct, year: year, month: month, day: day)
        }
    }
    
    enum CloudKitError: String, LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountTemporarilyUnavailable
        case iCloudAccountUnknown
    }
}
