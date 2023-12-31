//
//  Persistence.swift
//  SimpleConection
//
//  Created by Sergei Poluboiarinov on 17.06.2023.
//

import CoreData

struct CoreDataManager {
    
    static var preview: CoreDataManager = {
        let result = CoreDataManager(inMemory: true)
        let viewContext = result.container.viewContext
        let newContact = ContactEntity(context: viewContext)
        newContact.name = "Janet"
        newContact.component = Components.week.rawValue
        newContact.distance = Int16(5)
        newContact.isFavorite = false
        newContact.lastContact = Date().addingTimeInterval(-8743057)
        newContact.reminder = true
        
        let newMeeting = MeetingEntity(context: viewContext)
        newMeeting.contact = newContact
        newMeeting.date = Date().addingTimeInterval(-7834)
        newMeeting.describe = ";asldfjpqohgpqeihbvpwofijqw[peoi"
        newMeeting.feeling = Feelings.notTooBad.rawValue
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    static let shared = CoreDataManager()
    let container: NSPersistentCloudKitContainer
    let context: NSManagedObjectContext

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SimpleConection")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error {
            print("Error saving core data: \(error.localizedDescription)")
        }
    }
    
    func delete(_ object: NSManagedObject) throws {
            context.delete(object)
            try context.save()
        }
}

