//
//  ViewModel.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI
import EventKit
import CloudKit
import CoreData
import Combine

final class ViewModel: ObservableObject {
    
    @Published var fetchedContacts = [ContactEntity]()
    @Published var fetchedMeetings = [MeetingEntity]()
    @Published var filteredContacts = [ContactEntity]()
    @Published var searchText = ""
    @Published var isSignedIntoiCloud = false
    @Published var error = ""
    @Published var userName = ""
    @Published var email = ""
    @Published var telephone = ""
    @Published var permissionStatus = false
    @AppStorage("contacts_order") var contactsOrder: ContactsOrder = .alphabetical
    @AppStorage("notifications_request") var notificationsRequest = false
    
    private let notificationManager = NotificationManager.shared
    private let coreDataManager = CoreDataManager.shared
    private let hapticManager = HapticManager.shared
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
//        requestPermission()
//        getiCloudStatus()
//        fetchiCloudUserRecordID()
        
        getContacts(order: contactsOrder)
//        getMeetings()
        addSubscribers()
    }
    
    func getContacts(order: ContactsOrder) {
        let request = NSFetchRequest<ContactEntity>(entityName: "ContactEntity")
        var sort: NSSortDescriptor
        switch order {
        case .alphabetical:
            sort = NSSortDescriptor(keyPath: \ContactEntity.name, ascending: true)
        case .backwards:
            sort = NSSortDescriptor(keyPath: \ContactEntity.name, ascending: false)
        case .dueDate:
            sort = NSSortDescriptor(keyPath: \ContactEntity.name, ascending: true)
        case .favorites:
            sort = NSSortDescriptor(keyPath: \ContactEntity.isFavorite, ascending: true)
        }
        request.sortDescriptors = [sort]
        do {
            let contacts = try coreDataManager.context.fetch(request)
            switch order {
            case .alphabetical:
                fetchedContacts = contacts
            case .backwards:
                fetchedContacts = contacts
            case .dueDate:
                fetchedContacts = contacts.filter({getNextEventDate(component: Components(rawValue: $0.component!) ?? .day, lastContact: $0.lastContact!, interval: Int($0.distance)) <= Date()}).sorted(by: {getNextEventDate(component: Components(rawValue: $0.component!) ?? .day, lastContact: $0.lastContact!, interval: Int($0.distance)) < getNextEventDate(component: Components(rawValue: $1.component!) ?? .day, lastContact: $1.lastContact!, interval: Int($1.distance))})
            case .favorites:
                fetchedContacts = contacts.filter({$0.isFavorite == true})
            }
        } catch let error {
            print("Error fetching contacts: \(error.localizedDescription)")
        }
    }
    
    func returnAllContactsForNewContactFunction() -> [ContactEntity] {
        let request = NSFetchRequest<ContactEntity>(entityName: "ContactEntity")
        let sort = NSSortDescriptor(keyPath: \ContactEntity.name, ascending: true)
        request.sortDescriptors = [sort]
        var contacts = [ContactEntity]()
        do {
            contacts = try coreDataManager.context.fetch(request)
        } catch {
            print("Error fetching contacts: \(error.localizedDescription)")
        }
        return contacts
    }
    
    func getAllMeetings() {
        let request = NSFetchRequest<MeetingEntity>(entityName: "MeetingEntity")
        let sort = NSSortDescriptor(keyPath: \MeetingEntity.date, ascending: true)
        request.sortDescriptors = [sort]
        do {
            fetchedMeetings = try coreDataManager.context.fetch(request)
        } catch let error {
            print("Error fetching meetings: \(error.localizedDescription)")
        }
    }
    
    func getMeetingsOfContact(forContact contact: ContactEntity) {
        let request = NSFetchRequest<MeetingEntity>(entityName: "MeetingEntity")
        let filter = NSPredicate(format: "contact == %@", contact)
        request.predicate = filter
        
        do {
            fetchedMeetings = try coreDataManager.context.fetch(request)
        } catch let error {
            print("Error fetching meetings for \(contact): \(error.localizedDescription)")
        }
    }
    
    func returnMeetingsOfContact(forContact contact: ContactEntity) -> [MeetingEntity] {
        let request = NSFetchRequest<MeetingEntity>(entityName: "MeetingEntity")
        let filter = NSPredicate(format: "contact == %@", contact)
        request.predicate = filter
        var meetings = [MeetingEntity]()
        do {
            meetings = try coreDataManager.context.fetch(request)
        } catch let error {
            print("Error fetching meetings for \(contact): \(error.localizedDescription)")
        }
        return meetings
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
    
    func getDayCountFromLastContactToNext(component: Components, lastContact: Date, interval: Int) -> Int {
        let calendar = Calendar.current
        switch component {
        case .day:
            let nextContactDay = calendar.date(byAdding: Calendar.Component.day, value: interval, to: lastContact)!
            let distance = calendar.dateComponents([.day], from: lastContact, to: nextContactDay)
            return distance.day!
        case .week:
            let nextContactDay = calendar.date(byAdding: Calendar.Component.day, value: (interval * 7), to: lastContact)!
            let distance = calendar.dateComponents([.day], from: lastContact, to: nextContactDay)
            return distance.day!
        case .month:
            let nextContactDay = calendar.date(byAdding: Calendar.Component.month, value: interval, to: lastContact)!
            let distance = calendar.dateComponents([.day], from: lastContact, to: nextContactDay)
            return distance.day!
        case .year:
            let nextContactDay = calendar.date(byAdding: Calendar.Component.year, value: interval, to: lastContact)!
            let distance = calendar.dateComponents([.day], from: lastContact, to: nextContactDay)
            return distance.day!
        }
    }
    
    func daysFromLastEvent(lastEvent: Date, component: Components, Interval: Int) -> String {
        let calendar = Calendar.current
        let distance = calendar.dateComponents([.day], from: lastEvent, to: Date())
        let days = distance.day!
        switch days {
        case 1, 21:
            return "\(days)/\(getDayCountFromLastContactToNext(component: component, lastContact: lastEvent, interval: Interval)) day left"
        default:
            return "\(days)/\(getDayCountFromLastContactToNext(component: component, lastContact: lastEvent, interval: Interval)) days left"
        }
    }
    
    func daysFromLastEventCell(lastEvent: Date, component: Components, interval: Int) -> String {
        let calendar = Calendar.current
        let distance = calendar.dateComponents([.day], from: lastEvent, to: Date())
        let days = distance.day!
        switch days {
        case 1, 21:
            return "\(days)/\(getDayCountFromLastContactToNext(component: component, lastContact: lastEvent, interval: interval)) day left"
        default:
            return "\(days)/\(getDayCountFromLastContactToNext(component: component, lastContact: lastEvent, interval: interval)) days left"
        }
    }
    
    func deleteNotification(contact: ContactEntity) {
        notificationManager.cancelNotification(id: contact.id!.uuidString)
    }
    
    func setNotification(contact: ContactEntity, component: Components, lastContact: Date, interval: Int) {
        notificationManager.cancelNotification(id: contact.id!.uuidString)
        let date = getNextEventDate(component: Components(rawValue: component.rawValue) ?? .day, lastContact: lastContact, interval: Int(interval))
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        notificationManager.scheduleNotification(contact: contact, year: year, month: month, day: day)
    }
    
    func sendNotificationRequest() {
        notificationManager.requestAuthorization()
        notificationsRequest.toggle()
    }
    
    private func filterContacts(searchText: String) {
        guard !searchText.isEmpty else {
            filteredContacts = []
            return
        }
        let search = searchText.lowercased()
        filteredContacts = fetchedContacts.filter({ contact in
            let nameContainsSearch = contact.name!.lowercased().contains(search)
            return nameContainsSearch
        })
    }
    
    private func addSubscribers() {
        $searchText
//            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.filterContacts(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    func changeContactsOrder(order: ContactsOrder) {
        switch order {
        case .alphabetical:
            getContacts(order: .alphabetical)
        case .backwards:
            getContacts(order: .backwards)
        case .dueDate:
            getContacts(order: .dueDate)
        case .favorites:
            getContacts(order: .favorites)
        }
    }
}

//MARK: Core Date CRUD functions
extension ViewModel {
    func createContact(name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, lastContact: Date, reminder: Bool, meetingDate: Date, meetingDescribe: String, meetingFeeling: Feelings) {
        withAnimation {
            let newContact = ContactEntity(context: coreDataManager.context)
            newContact.name = name
            newContact.birthday = birthday
            newContact.isFavorite = isFavorite
            newContact.distance = Int16(distance)
            newContact.component = component.rawValue
            newContact.lastContact = lastContact
            newContact.reminder = reminder
            newContact.id = UUID()
            
            let newMeeting = MeetingEntity(context: coreDataManager.context)
            newMeeting.id = UUID()
            newMeeting.date = meetingDate
            newMeeting.describe = meetingDescribe
            newMeeting.feeling = meetingFeeling.rawValue
            
            newContact.addToMeetings(newMeeting)
            
            coreDataManager.save()
            
            fetchedContacts.removeAll()
            getContacts(order: contactsOrder)
            let contacts = returnAllContactsForNewContactFunction()
            
            if reminder {
                setNotification(contact: contacts.first(where: {$0.id == newContact.id})!, component: component, lastContact: lastContact, interval: distance)
            }
        }
    }
    
    func editContact(contact: ContactEntity, name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, lastContact: Date, reminder: Bool, meetingDate: Date, meetingDescribe: String, meetingFeeling: Feelings) {
        withAnimation {
            contact.name = name
            contact.birthday = birthday
            contact.isFavorite = isFavorite
            contact.distance = Int16(distance)
            contact.component = component.rawValue
            contact.lastContact = lastContact
            contact.reminder = reminder
            
            coreDataManager.save()
            
            fetchedContacts.removeAll()
            getContacts(order: contactsOrder)
            
            if contact.meetings == nil {
                createMeeting(contact: contact, meetingDate: meetingDate, meetingDescribe: meetingDescribe, meetingFeeling: meetingFeeling)
            }
            
            if reminder {
                setNotification(contact: contact, component: component, lastContact: lastContact, interval: distance)
            } else {
                deleteNotification(contact: contact)
            }
        }
    }
    
    func deleteContact(offsets: IndexSet) {
        withAnimation {
            notificationManager.cancelNotification(id: offsets.map { fetchedContacts[$0] }.first?.id?.uuidString ?? "")
            offsets.map { fetchedContacts[$0] }.forEach(coreDataManager.context.delete)

            do {
                try coreDataManager.context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            fetchedContacts.removeAll()
            getContacts(order: contactsOrder)
        }
    }
    
    func createMeeting(contact: ContactEntity, meetingDate: Date, meetingDescribe: String, meetingFeeling: Feelings) {
        withAnimation {
            getMeetingsOfContact(forContact: contact)
            let maxDate = fetchedMeetings.max(by: {$0.date! > $1.date!})!.date!
            
            let newMeeting = MeetingEntity(context: coreDataManager.context)
            newMeeting.id = UUID()
            newMeeting.date = meetingDate
            newMeeting.describe = meetingDescribe
            newMeeting.feeling = meetingFeeling.rawValue
            
            contact.addToMeetings(newMeeting)
            
            if meetingDate > maxDate {
                contact.lastContact = meetingDate
                
                if contact.reminder {
                    setNotification(contact: contact, component: Components(rawValue: contact.component!)!, lastContact: meetingDate, interval: Int(contact.distance))
                }
            }
            
            coreDataManager.save()
            
            fetchedMeetings.removeAll()
            getMeetingsOfContact(forContact: contact)
            
            
        }
    }
    
    func editMeeting(contact: ContactEntity, meeting: MeetingEntity, meetingDate: Date, meetingDescribe: String, meetingFeeling: Feelings) {
        withAnimation {
            fetchedMeetings.removeAll()
            getMeetingsOfContact(forContact: contact)
            fetchedMeetings.removeAll(where: {$0.id == meeting.id})
            if fetchedMeetings.count > 0 {
                let maxDate = fetchedMeetings.max(by: {$0.date! > $1.date!})!.date!
                if meetingDate > maxDate {
                    contact.lastContact = meetingDate
                    setNotification(contact: contact, component: Components(rawValue: contact.component!)!, lastContact: meetingDate, interval: Int(contact.distance))
                }
            } else {
                contact.lastContact = meetingDate
                setNotification(contact: contact, component: Components(rawValue: contact.component!)!, lastContact: meetingDate, interval: Int(contact.distance))
            }
            
            meeting.date = meetingDate
            meeting.describe = meetingDescribe
            meeting.feeling = meetingFeeling.rawValue
            
            coreDataManager.save()
            
            fetchedMeetings.removeAll()
            fetchedContacts.removeAll()
            getContacts(order: contactsOrder)
            getMeetingsOfContact(forContact: contact)
        }
    }
    
    func deleteMeeting(contact: ContactEntity, offsets: IndexSet) {
        withAnimation {
            offsets.map { fetchedMeetings[$0] }.forEach(coreDataManager.context.delete)
            
            coreDataManager.save()
            
            fetchedMeetings.removeAll()
            fetchedContacts.removeAll()
            getContacts(order: contactsOrder)
            getMeetingsOfContact(forContact: contact)
        }
    }
    
    func toggleFavorite(contact: ContactEntity) {
        contact.isFavorite.toggle()
        
        coreDataManager.save()
        
        fetchedContacts.removeAll()
        getContacts(order: contactsOrder)
    }
    
    func updateLastContact(contact: ContactEntity) {
        let array = fetchedMeetings
        let date = array.map{$0.date!}.max()
        contact.lastContact = date
        
        coreDataManager.save()
        
        fetchedContacts.removeAll()
        getContacts(order: contactsOrder)
        
        if contact.reminder {
            deleteNotification(contact: contact)
            setNotification(contact: contact, component: Components(rawValue: contact.component!) ?? .day, lastContact: contact.lastContact ?? Date(), interval: Int(contact.distance))
        }
    }
    
    func deleteMeetingFromMeetingView(contact: ContactEntity, meeting: MeetingEntity) {
        coreDataManager.context.delete(meeting)
        coreDataManager.save()
        
        fetchedMeetings.removeAll()
        getMeetingsOfContact(forContact: contact)
        
        if fetchedMeetings.count > 0 {
            let maxDate = fetchedMeetings.max(by: {$0.date! > $1.date!})!.date!
            
            contact.lastContact = maxDate
            coreDataManager.save()
            
            if contact.reminder {
                setNotification(contact: contact, component: Components(rawValue: contact.component!)!, lastContact: maxDate, interval: Int(contact.distance))
            }
            
            fetchedContacts.removeAll()
            getContacts(order: contactsOrder)
        } else {
            
        }
    }
}

// MARK: CloudKit
extension ViewModel {
    // ‼️
//    func moveContact(from: IndexSet, to: Int) {
//        fetchedContacts
//        var contacts = fetchedContacts.map{$0}
//        contacts.move(fromOffsets: from, toOffset: to)
//    }
    
//    enum CloudKitError: String {
//        case iCloudAccountNotDetermined
//        case iCloudAccountRestricted
//        case iCloudAccountNotFound
//        case iCloudAccountTemporarilyUnavailable
//        case iCloudAccountUnknown
//    }
    
//    func getiCloudStatus() {
//        CKContainer.default().accountStatus { [weak self] returnedStatus, returnedError in
//            DispatchQueue.main.async {
//                switch returnedStatus {
//                case .couldNotDetermine:
//                    self?.error = CloudKitError.iCloudAccountNotDetermined.rawValue
//                case .available:
//                    self?.isSignedIntoiCloud = true
//                case .restricted:
//                    self?.error = CloudKitError.iCloudAccountRestricted.rawValue
//                case .noAccount:
//                    self?.error = CloudKitError.iCloudAccountNotFound.rawValue
//                case .temporarilyUnavailable:
//                    self?.error = CloudKitError.iCloudAccountTemporarilyUnavailable.rawValue
//                @unknown default:
//                    self?.error = CloudKitError.iCloudAccountUnknown.rawValue
//                }
//            }
//        }
//    }
//
//    func discoveriCloudUser(id: CKRecord.ID) {
//        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] returnedIdentity, returnedError in
//            DispatchQueue.main.async {
//
//                if let name = returnedIdentity?.nameComponents?.familyName {
//                    self?.userName = name
//                }
//
//                // We can't get email because we get permission by id. We can get email if we get permission by email
//                if let email = returnedIdentity?.lookupInfo?.emailAddress {
//                    self?.email = email
//                }
//
//                // We can't get number because we get permission by id. We can get number if we get permission by number
//                if let phone = returnedIdentity?.lookupInfo?.phoneNumber {
//                    self?.telephone = phone
//                }
//            }
//        }
//    }
//
//    func fetchiCloudUserRecordID() {
//        CKContainer.default().fetchUserRecordID { [weak self] returnedID, returnedError in
//            if let id = returnedID {
//                self?.discoveriCloudUser(id: id)
//            }
//        }
//    }
    
//    func requestPermission() {
//        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
//            DispatchQueue.main.async {
//                if returnedStatus == .granted {
//                    self?.permissionStatus = true
//                }
//            }
//        }
//    }
}
