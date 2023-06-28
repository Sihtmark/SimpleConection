//
//  ContactListView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI
import CloudKit
import Combine

protocol CloudKitProtocol {
    init?(record: CKRecord)
    var record: CKRecord {get}
}

class CloudKitUtility {
    
    enum CloudKitError: String, LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountTemporarilyUnavailable
        case iCloudAccountUnknown
        case iCloudApplicationPermissionNotGranted
        case iCloudCouldNotFetchUserRecordID
        case iCloudCouldNotDiscoverUser
    }
}

//MARK: USER FUNCTIONS
extension CloudKitUtility {
    static private func getCloudStatus(completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            switch returnedStatus {
            case .available:
                completion(.success(true))
            case .couldNotDetermine:
                completion(.failure(CloudKitError.iCloudAccountNotDetermined))
            case .restricted:
                completion(.failure(CloudKitError.iCloudAccountRestricted))
            case .noAccount:
                completion(.failure(CloudKitError.iCloudAccountNotFound))
            case .temporarilyUnavailable:
                completion(.failure(CloudKitError.iCloudAccountTemporarilyUnavailable))
            @unknown default:
                completion(.failure(CloudKitError.iCloudAccountUnknown))
            }
        }
    }
    
    static func getCloudStatus() -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.getCloudStatus { result in
                promise(result)
            }
        }
    }
    
    static private func requestApplicationPermission(completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { returnedStatus, returnedError in
            if returnedStatus == .granted {
                completion(.success(true))
            } else {
                completion(.failure(CloudKitError.iCloudApplicationPermissionNotGranted))
            }
        }
    }
    
    static public func requestApplicationPermission() -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.requestApplicationPermission { result in
                promise(result)
            }
        }
    }
    
    static func fetchUserRecordID(completion: @escaping (Result<CKRecord.ID, Error>) -> ()) {
        CKContainer.default().fetchUserRecordID { returnedID, returnedError in
            if let id = returnedID {
                completion(.success(id))
            } else {
                completion(.failure(CloudKitError.iCloudCouldNotFetchUserRecordID))
            }
        }
    }
    
    static private func discoverUserIdentity(id: CKRecord.ID, completion: @escaping (Result<String, Error>) -> ()) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { returnedIdentity, returnedError in
            if let name = returnedIdentity?.nameComponents?.givenName {
                completion(.success(name))
            } else {
                completion(.failure(CloudKitError.iCloudCouldNotDiscoverUser))
            }
        }
    }
    
    static private func discoverUserIdentity(completion: @escaping (Result<String, Error>) -> ()) {
        fetchUserRecordID { fetchCompletion in
            switch fetchCompletion {
            case .success(let recordID):
                CloudKitUtility.discoverUserIdentity(id: recordID, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static public func discoverUserIdentity() -> Future<String, Error> {
        Future { promise in
            CloudKitUtility.discoverUserIdentity { result in
                promise(result)
            }
        }
    }
    
    
}

//MARK: CRUD FUNCTIONS
extension CloudKitUtility {
    
    static func fetch<T: CloudKitProtocol>(predicate: NSPredicate, recordType: CKRecord.RecordType, sortDescriptors: [NSSortDescriptor]? = nil, resultsLimit: Int? = nil) -> Future<[T], Error> {
        Future { promise in
            CloudKitUtility.fetch(predicate: predicate, recordType: recordType, sortDescriptors: sortDescriptors, resultsLimit: resultsLimit) { (returnedItems: [T]) in
                promise(.success(returnedItems))
            }
        }
    }
    
    static private func fetch<T: CloudKitProtocol>(predicate: NSPredicate, recordType: CKRecord.RecordType, sortDescriptors: [NSSortDescriptor]? = nil, resultsLimit: Int? = nil, completion: @escaping (_ items: [T]) -> Void) {
        
        // create operation
        let queryOperation = createOperation(predicate: predicate, recordType: recordType, sortDescriptors: sortDescriptors, resultsLimit: resultsLimit)
        
        // get items in query
        var returnedItems = [T]()
        addRecordMatchedBlock(queryOperation: queryOperation) { item in
            returnedItems.append(item)
        }
        
        // query completion
        addQueryResultBlock(queryOperation: queryOperation) { finished in
            completion(returnedItems)
        }
        
        // execute operation
        add(operation: queryOperation)
    }
    
    static private func createOperation(predicate: NSPredicate, recordType: CKRecord.RecordType, sortDescriptors: [NSSortDescriptor]? = nil, resultsLimit: Int? = nil) -> CKQueryOperation {
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        let queryOperation = CKQueryOperation(query: query)
        if let limit = resultsLimit {
            queryOperation.resultsLimit = limit
        }
        return queryOperation
        
    }
    
    static private func addRecordMatchedBlock<T: CloudKitProtocol>(queryOperation: CKQueryOperation, completion: @escaping (_ item: T) -> Void) {
        queryOperation.recordMatchedBlock = { returnedRecordID, returnedRecordResult in
            switch returnedRecordResult {
            case .success(let record):
                guard let item = T(record: record) else {return}
                completion(item)
            case .failure:
                break
            }
        }
    }
    
    static private func addQueryResultBlock(queryOperation: CKQueryOperation, completion: @escaping (_ finished: Bool) -> Void) {
        queryOperation.queryResultBlock = { returnedResult in
            completion(true)
        }
    }
    
    static private func add(operation: CKDatabaseOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    static func add<T: CloudKitProtocol>(item: T, completion: @escaping (Result<Bool, Error>) -> Void) {
        // save to CloudKit
        save(record: item.record, completion: completion)
    }
    
    static func update<T: CloudKitProtocol>(item: T, completion: @escaping (Result<Bool, Error>) -> Void) {
        // save to CloudKit
        add(item: item, completion: completion)
    }
    
    static func save(record: CKRecord, completion: @escaping (Result<Bool, Error>) -> Void) {
        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, returnedError in
            if let error = returnedError {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    static func delete<T: CloudKitProtocol>(item: T) -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.delete(item: item, completion: promise)
        }
    }
    
    static private func delete<T: CloudKitProtocol>(item: T, completion: @escaping (Result<Bool, Error>) -> Void) {
        CloudKitUtility.delete(record: item.record, completion: completion)
    }
    
    static private func delete(record: CKRecord, completion: @escaping (Result<Bool, Error>) -> Void) {
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { returnedRecordID, returnedError in
            if let error = returnedError {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
}

//MARK: PUSH NOTIFICATIONS
extension CloudKitUtility {
    
    // request notification permissions
    static func requestNotificationPermissions(authorizationOptions: UNAuthorizationOptions) {
        UNUserNotificationCenter.current().requestAuthorization(options: authorizationOptions) { success, error in
            if let error = error {
                print(error)
            } else if success {
                print("Notifications permission success")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notifications permission failure")
            }
        }
    }
    
    // subscribe to notifications
    static func subscribeToNotifications(recordType: String, notificationTitle: String, notificationBody: String, subscriptionID: String) {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: .firesOnRecordCreation)
        let notification = CKSubscription.NotificationInfo()
        notification.title = notificationTitle
        notification.alertBody = notificationBody
        notification.soundName = "default"
        subscription.notificationInfo = notification
        CKContainer.default().publicCloudDatabase.save(subscription) { record, error in
            if let error = error {
                print(error)
            } else {
                print("Successfully subscribed to notifications")
            }
        }
    }
    
    // unsubscribe from notifications
    static func unsubscribeFromNotifications(subscriptionID: String) {
//        CKContainer.default().publicCloudDatabase.fetchAllSubscriptions(completionHandler: <#T##([CKSubscription]?, Error?) -> Void#>)
        
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: subscriptionID) { id, error in
            if let error = error {
                print(error)
            } else {
                print("Successfully unsubscribed")
            }
        }
    }
}
