//
//  ContactListView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

struct ContactListView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @State private var isAdding: ContactEntity?
    @State private var lastContact = Date()
    @State private var date = Date()
    @State private var feeling = Feelings.notTooBad
    @State private var describe = ""
    @State private var showAlert = false
    @State private var isAddingNewContact = false
    @State var animate = false
    
    var dateRange: ClosedRange<Date> {
        var dateComponents = DateComponents()
        dateComponents.year = 1850
        dateComponents.month = 1
        dateComponents.day = 1
        let calendar = Calendar(identifier: .gregorian)
        let min = calendar.date(from: dateComponents)!
        let max = Date()
        return min...max
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if vm.fetchedContacts.count == 0 {
                    NoContactsView()
                } else {
                    contactList
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
            .frame(maxWidth: 550)
            .listStyle(.inset)
            .navigationTitle(vm.contactsTitle())
            .searchable(text: $vm.searchText, prompt: Text("Search contact by name..."))
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    menu
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isAddingNewContact.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $isAdding) { contact in
                newMeetingSheet
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.7), .large])
            }
            .sheet(isPresented: $isAddingNewContact) {
                AddNewContactView()
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    func addAnimation() {
        guard !animate else {return}
        DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever()) {
                animate.toggle()
            }
        }
    }
}

struct AllCustomersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContactListView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(ViewModel())
        NavigationStack {
            ContactListView()
                .preferredColorScheme(.light)
        }
        .environmentObject(ViewModel())
    }
}

extension ContactListView {
    
    var menu: some View {
        Menu(content: {
            Button(ContactsOrder.alphabetical.rawValue) {
                vm.changeContactsOrder(order: .alphabetical)
            }
            Button(ContactsOrder.backwards.rawValue) {
                vm.changeContactsOrder(order: .backwards)
            }
            Button(ContactsOrder.favorites.rawValue) {
                vm.changeContactsOrder(order: .favorites)
            }
            Button(ContactsOrder.dueDate.rawValue) {
                vm.changeContactsOrder(order: .dueDate)
            }
        }, label: {
            Image(systemName: "list.bullet.circle.fill")
        })
    }
    
    var contactList: some View {
        List {
            ForEach(vm.isSearching ? vm.filteredContacts : vm.fetchedContacts) { contact in
                ZStack(alignment: .leading) {
                    ContactCellView(contact: contact)
                    NavigationLink {
                        ContactView(contact: contact)
                    } label: {
                        EmptyView()
                    }
                    .opacity(0.0)
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        isAdding = contact
                    } label: {
                        Label("Contact", systemImage: "person.fill.checkmark")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false, content: {
                    Button {
                        vm.toggleFavorite(contact: contact)
                    } label: {
                        Label(contact.isFavorite ? "Remove" : "Add", systemImage: contact.isFavorite ? "star.slash" : "star.fill")
                    }
                    .tint(.yellow)
                })
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: vm.deleteContact)
        }
    }
    
    var newMeetingSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    Spacer()
                    DatePicker(selection: $date, in: dateRange, displayedComponents: .date) {}
                        .foregroundColor(.theme.accent)
                        .datePickerStyle(.wheel)
                        .frame(width: 320, height: 220)
                        .padding(.trailing, 7.5)
                        .overlay(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.gray.opacity(0.2))
                                .allowsHitTesting(false)
                    }
                    Spacer()
                }
                Picker("", selection: $feeling) {
                    ForEach(Feelings.allCases, id: \.self) { feeling in
                        Text(feeling.rawValue).tag(feeling)
                    }
                }
                .pickerStyle(.segmented)
                TextEditor(text: $describe)
                    .frame(height: 50)
                    .foregroundColor(.theme.secondaryText)
                    .padding(10)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.gray.opacity(0.2))
                            .allowsHitTesting(false)
                    }
                HStack {
                    Spacer()
                    Button {
                        vm.createMeeting(contact: isAdding!, meetingDate: date, meetingDescribe: describe, meetingFeeling: feeling)
                        isAdding = nil
                        date = Date()
                        feeling = .notTooBad
                        describe = ""
                    } label: {
                        Text("Save")
                            .bold()
                            .padding(10)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, 30)
            .padding(.horizontal)
        }
    }
}
