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
    @Published var cache: NSCache<NSString, NSData>? = nil
    @Published var contacts = [ContactStruct]()
    
    init() {
        requestPermission()
        getiCloudStatus()
        fetchiCloudUserRecordID()
        fetchContactsFromiCloudKit()
    }
    
    func createNewContact(name: String, birthday: Date, distance: Int, component: Components, lastContact: Date, reminder: Bool, feeling: Feelings, describe: String, isFavorite: Bool) {
        
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
            contact: newContact,
            record: sampleData()!
        )
        
        if reminder {
            setNotification(contactStruct: newCustomer)
        }
        
        saveContactToiCloudKit(contact: newCustomer)
        fetchContactsFromiCloudKit()
    }
    
    func updateContact(client: ContactStruct, name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, lastContact: Date, reminder: Bool, feeling: Feelings, describe: String) {
//        if let index = contacts.firstIndex(where: {$0.id == client.id}) {
//            contacts[index] = client.updateInfo(name: name, birthday: birthday, isFavorite: isFavorite, distance: distance, component: component, reminder: reminder)
//            updateContactIniCloudKit(contact: contacts[index])
//        }
        updateContactIniCloudKit(contact: client.updateInfo(name: name, birthday: birthday, isFavorite: isFavorite, distance: distance, component: component, reminder: reminder))
        fetchContactsFromiCloudKit()
    }
    
    func updateEvent(contact: ContactStruct) {
//        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
//            contacts[index] = contact.changeLastContact(date: Date())
//        }
        updateContactIniCloudKit(contact: contact.changeLastContact(date: Date()))
        fetchContactsFromiCloudKit()
    }
    
//    func deleteContact(indexSet: IndexSet) {
//        contacts.remove(atOffsets: indexSet)
//    }
    
    // ‼️
    func moveContact(from: IndexSet, to: Int) {
        contacts.move(fromOffsets: from, toOffset: to)
    }
    
    func updateMeeting(contact: ContactStruct, meeting: Meeting, date: Date, feeling: Feelings, describe: String) {
        var changedContact = contact
        if let i = contact.contact.allEvents.firstIndex(where: {$0.id == meeting.id}) {
            changedContact.contact.allEvents[i].date = date
            changedContact.contact.allEvents[i].feeling = feeling
            changedContact.contact.allEvents[i].describe = describe
        }
        updateContactIniCloudKit(contact: changedContact)
        fetchContactsFromiCloudKit()
    }
    
    func deleteMeeting(contact: ContactStruct, meeting: Meeting) {
        var changedContact = contact
        if let i = contact.contact.allEvents.firstIndex(where: {$0.id == meeting.id}) {
            changedContact.contact.allEvents.remove(at: i)
        }
        updateContactIniCloudKit(contact: changedContact)
        fetchContactsFromiCloudKit()
    }
    
    func toggleFavorite(contact: ContactStruct) {
        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
            contacts[index].isFavorite.toggle()
            updateContactIniCloudKit(contact: contacts[index])
        }
        var changedContact = contact
        changedContact.isFavorite.toggle()
        updateContactIniCloudKit(contact: changedContact)
        fetchContactsFromiCloudKit()
    }
    
    func addMeeting(contact: ContactStruct, date: Date, feeling: Feelings, describe: String) {
        let newMeeting = Meeting(date: date, feeling: feeling, describe: describe)
        var changedContact = contact
        changedContact.contact.allEvents.append(newMeeting)
        changedContact.contact.lastContact = changedContact.contact.lastContact < date ? date : changedContact.contact.lastContact
        if changedContact.contact.reminder {
            setNotification(contactStruct: changedContact)
        }
        updateContactIniCloudKit(contact: changedContact)
        fetchContactsFromiCloudKit()
    }
    
    enum CloudKitError: String, LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountTemporarilyUnavailable
        case iCloudAccountUnknown
    }
    
    func saveContactToiCloudKit(contact: ContactStruct) {
        let record = CKRecord(recordType: "Contacts")
        let contactWithRecord = contact.addRecord(metaData: returnRecordAsData(record))
        if let encodedData = try? JSONEncoder().encode(contactWithRecord) {
            record["data"] = encodedData
            saveItemToiCloudKit(record: record)
        }
    }
    
    private func saveItemToiCloudKit(record: CKRecord) {
        CKContainer.default().publicCloudDatabase.save(record) {[weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                self?.fetchContactsFromiCloudKit()
            }
        }
    }
    
    func fetchContactsFromiCloudKit() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Contacts", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        var returnedItems = [ContactStruct]()
        
        queryOperation.recordMatchedBlock = { returnedRecordID, returnedRecordResult in
            switch returnedRecordResult {
            case .success(let record):
                if let contact = record["data"] as? Data {
                    guard let savedItem = try? JSONDecoder().decode(ContactStruct.self, from: contact) else {return}
                    returnedItems.append(savedItem)
                }
            case .failure(let error):
                print("Error recordMatchedBlock: \(error.localizedDescription)")
            }
        }
        
        queryOperation.queryResultBlock = { [weak self] returnedResult in
            print("RETURNED RESULT: \(returnedResult)")
            DispatchQueue.main.async {
                self?.contacts = returnedItems
            }
        }
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func updateContactIniCloudKit(contact: ContactStruct) {
        guard let record = try? extractCloudRecord(from: contact), let encodedData = try? JSONEncoder().encode(contact) else {
            print("‼️ We cannot update \(contact.name) in CloudKit. \(contact.name) doesn't contain record ‼️")
            return
        }
        record["data"] = encodedData
        saveItemToiCloudKit(record: record)
    }
    
    func deleteContactIniCloudKit(indexSet: IndexSet) {
        guard let index = indexSet.first else {return}
        let contact = contacts[index]
        try? CKContainer.default().publicCloudDatabase.delete(withRecordID: extractCloudRecord(from: contact)!.recordID) { returnedRecordID, returnedError in
//            DispatchQueue.main.async {
//                self?.contacts.remove(at: index)
//            }
        }
        fetchContactsFromiCloudKit()
    }
    
    // Remote Records
    func storeCloudRecord(_ record: CKRecord, on contact: ContactStruct) {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        if let index = contacts.firstIndex(where: {$0.id == contact.id}) {
            contacts[index] = contact.addRecord(metaData: coder.encodedData)
        }
    }
    
    // Remote Records
    func returnRecordAsData(_ record: CKRecord) -> Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        return coder.encodedData
    }
    
    // Remote Records
    func extractCloudRecord(from contact: ContactStruct) throws -> CKRecord? {
        let metadata = contact.record
        let coder = try NSKeyedUnarchiver(forReadingFrom: metadata)
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        return record
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
    
    func listOrder(order: FilterMainView) -> [ContactStruct] {
        switch order {
        case .standardOrder:
            return contacts
        case .alphabeticalOrder:
            return contacts.sorted(by: {$0.name > $1.name})
        case .dueDateOrder:
            return contacts.sorted(by: {$0.contact.getNextEventDate() < $1.contact.getNextEventDate()})
        case .favoritesOrder:
            return contacts.filter{$0.isFavorite}
        }
    }
    
    func deleteNotification(contactStruct: ContactStruct) {
        nm.cancelNotification(id: contactStruct.id)
    }
    
    func setNotification(contactStruct: ContactStruct) {
        nm.cancelNotification(id: contactStruct.id)
        let contact = contactStruct.contact
        let date = getNextEventDate(component: contact.component, lastContact: contact.lastContact, interval: contact.distance)
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        nm.scheduleNotification(contact: contactStruct, year: year, month: month, day: day)
    }
    
    func sampleData() -> Data? {
        let encodedData = try? JSONEncoder().encode("contact")
        return encodedData
    }
}
