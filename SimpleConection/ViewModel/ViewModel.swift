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

class ViewModel: ObservableObject {

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ContactEntity.name, ascending: true)], animation: .default)
    var fetchedContacts: FetchedResults<ContactEntity>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MeetingEntity.date, ascending: true)], animation: .default)
    var fetchedMeetings: FetchedResults<MeetingEntity>
    
    let nm = NotificationManager()
    
    @Published var isSignedIntoiCloud = false
    @Published var error = ""
    @Published var userName = ""
    @Published var email = ""
    @Published var telephone = ""
    @Published var permissionStatus = false
    
    init() {
        requestPermission()
        getiCloudStatus()
        fetchiCloudUserRecordID()
    }
    
    // ‼️
//    func moveContact(from: IndexSet, to: Int) {
//        fetchedContacts
//        var contacts = fetchedContacts.map{$0}
//        contacts.move(fromOffsets: from, toOffset: to)
//    }
    
    enum CloudKitError: String {
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountNotFound
        case iCloudAccountTemporarilyUnavailable
        case iCloudAccountUnknown
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
    
    func deleteNotification(contact: ContactEntity) {
        nm.cancelNotification(id: contact.id!.uuidString)
    }
    
    func setNotification(contact: ContactEntity) {
        nm.cancelNotification(id: contact.id!.uuidString)
        let date = getNextEventDate(component: Components(rawValue: contact.component!)!, lastContact: contact.lastContact!, interval: Int(contact.distance))
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        nm.scheduleNotification(contact: contact, year: year, month: month, day: day)
    }
}

//MARK: Core Date CRUD functions
extension ViewModel {
    func createContact(name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, lastContact: Date, reminder: Bool, meetingDate: Date, meetingDescribe: String, meetingFeeling: Feelings, context: NSManagedObjectContext) {
        withAnimation {
            let newContact = ContactEntity(context: context)
            newContact.name = name
            newContact.birthday = birthday
            newContact.isFavorite = isFavorite
            newContact.distance = Int16(distance)
            newContact.component = component.rawValue
            newContact.lastContact = lastContact
            newContact.reminder = reminder
            newContact.id = UUID()
            
            let newMeeting = MeetingEntity(context: context)
            newMeeting.id = UUID()
            newMeeting.date = meetingDate
            newMeeting.describe = meetingDescribe
            newMeeting.feeling = meetingFeeling.rawValue
            
            newContact.meetings!.adding(newMeeting)
            newMeeting.contact = newContact
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func createMeeting(contact: ContactEntity, meetingDate: Date, meetingDescribe: String, meetingFeeling: Feelings, context: NSManagedObjectContext) {
        withAnimation {
            let newMeeting = MeetingEntity(context: context)
            newMeeting.date = meetingDate
            newMeeting.describe = meetingDescribe
            newMeeting.feeling = meetingFeeling.rawValue
            newMeeting.contact = contact
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func editContact(contact: ContactEntity, name: String, birthday: Date, isFavorite: Bool, distance: Int, component: Components, lastContact: Date, reminder: Bool, context: NSManagedObjectContext) {
        withAnimation {
            contact.name = name
            contact.birthday = birthday
            contact.isFavorite = isFavorite
            contact.distance = Int16(distance)
            contact.component = component.rawValue
            contact.lastContact = lastContact
            contact.reminder = reminder
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func editMeeting(meeting: MeetingEntity, meetingDate: Date, meetingDescribe: String, meetingFeeling: Feelings, context: NSManagedObjectContext) {
        withAnimation {
            meeting.date = meetingDate
            meeting.describe = meetingDescribe
            meeting.feeling = meetingFeeling.rawValue
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteMeeting(offsets: IndexSet, context: NSManagedObjectContext) {
        withAnimation {
            offsets.map { fetchedMeetings[$0] }.forEach(context.delete)

            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func toggleFavorite(contact: ContactEntity, isFavorite: Bool, context: NSManagedObjectContext) {
        withAnimation {
            contact.isFavorite = isFavorite
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func updateLastContact(contact: ContactEntity, context: NSManagedObjectContext) {
        var array = fetchedMeetings.filter({$0.contact == contact})
        let date = array.map{$0.date!}.max()
        contact.lastContact = date
        
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func deleteMeetingFromMeetingView(meeting: MeetingEntity, context: NSManagedObjectContext) {
        context.delete(meeting)
        
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
