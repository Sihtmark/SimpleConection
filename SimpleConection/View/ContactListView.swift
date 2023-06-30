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
    @State private var filter: FilterMainView = .standardOrder
    @State private var showAlert = false
    @State private var notifications = false
    
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
            List {
                if vm.fetchedContacts.count == 0 {
                    Text("В вашем списке пока-что нет ни одного контакта 🧐\n\nНажмите '+' в правом верхнем углу, чтобы добавить ваш первый контакт.")
                        .frame(maxWidth: 550, alignment: .center)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.theme.secondaryText)
                        .padding(.top, 40)
                }
                ForEach(vm.fetchedContacts) { contact in
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
                .onDelete(perform: deleteContact)
//                .onMove(perform: vm.moveContact)
            }
            .ignoresSafeArea(edges: .bottom)
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
            .frame(maxWidth: 550)
            .listStyle(.inset)
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAlert.toggle()
                    } label: {
                        Image(systemName: "slider.vertical.3")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddNewContactView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Contact filter", isPresented: $showAlert, actions: {
                Button("Все по алфавиту") {
                    filter = .alphabeticalOrder
                }
                Button("По дате общения") {
                    filter = .dueDateOrder
                }
                Button("Только избранные") {
                    filter = .favoritesOrder
                }
                Button("Без фильтра", role: .destructive) {
                    filter = .standardOrder
                }
            })
            .sheet(item: $isAdding) { contact in
                sheetView
            }
        }
    }
    
    func deleteContact(offsets: IndexSet) {
        withAnimation {
            offsets.map { vm.fetchedContacts[$0] }.forEach(vm.coreDataManager.context.delete)

            do {
                try vm.coreDataManager.context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
    var sheetView: some View {
        VStack {
            HStack {
                Button {
                    isAdding = nil
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                Spacer()
            }
            .padding(.top, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack {
                        Spacer()
                        DatePicker(selection: $date, in: dateRange, displayedComponents: .date) {}
                            .foregroundColor(.theme.accent)
                            .datePickerStyle(.wheel)
                            .frame(width: 320, height: 180)
                            .padding(.trailing, 7.5)
                            .overlay(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.gray.opacity(0.2))
                                    .allowsHitTesting(false)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    Picker("", selection: $feeling) {
                        ForEach(Feelings.allCases, id: \.self) { feeling in
                            Text(feeling.rawValue).tag(feeling)
                        }
                    }
                    .pickerStyle(.segmented)
                    TextEditor(text: $describe)
                        .frame(height: 200)
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
//                            vm.addMeeting(contact: isAdding!, date: date, feeling: feeling, describe: describe)
                            vm.updateLastContact(contact: isAdding!)
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
            }
        }
        .padding(.horizontal)
    }
}
