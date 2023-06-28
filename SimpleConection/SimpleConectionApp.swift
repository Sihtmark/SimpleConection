//
//  OnTuchRussianApp.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

@main
struct SimpleConectionApp: App {
    
    @StateObject private var vm = ViewModel()
    
    let persistenceController = PersistenceController.shared
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.theme.standard)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.theme.standard)]
    }
    
    var body: some Scene {
        WindowGroup {
            ContactListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(vm)
        }
    }
}
