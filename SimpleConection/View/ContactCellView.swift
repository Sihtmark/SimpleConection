//
//  ContactCellView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

struct ContactCellView: View {
    
    @EnvironmentObject private var vm: ViewModel
    let contact: ContactEntity
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.theme.accent, lineWidth: 0.4)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(contact.name!)
                        .bold()
                        .font(.headline)
                        .foregroundColor(.theme.standard)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(vm.daysFromLastEventCell(lastEvent: contact.lastContact ?? Date()))
                    .foregroundColor(vm.getNextEventDate(component: Components(rawValue: contact.component!)!, lastContact: contact.lastContact ?? Date(), interval: Int(contact.distance)) > Date() ? .theme.green : .theme.red)
                    .font(.caption)
                    .bold()
                    .padding(.trailing)
                VStack {
                    if contact.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct CustomerCellView_Previews: PreviewProvider {
    static var previews: some View {
        ContactCellView(contact: ViewModel().fetchedContacts.first!)
            .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
            .environmentObject(ViewModel())
            .preferredColorScheme(.dark)
        ContactCellView(contact: ViewModel().fetchedContacts.first!)
            .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
            .environmentObject(ViewModel())
            .preferredColorScheme(.light)
    }
}

