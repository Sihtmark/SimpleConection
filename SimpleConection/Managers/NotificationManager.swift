//
//  NotificationManager.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI
import UserNotifications
import CoreLocation


class NotificationManager {
    
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) { success, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    print("SUCCESS!!!")
                }
            }
    }
    
    func scheduleNotification(contact: ContactEntity, year: Int, month: Int, day: Int) {
        let content = UNMutableNotificationContent()
        content.title = "It's time to talk to \(contact.name!)! ⏰"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = 9
        dateComponents.minute = 15
        let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: contact.id!.uuidString,
            content: content,
            trigger: calendarTrigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(id: String) {
        
        // will cancel any upcoming notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        
        // remove from notification-center
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
    }
}
