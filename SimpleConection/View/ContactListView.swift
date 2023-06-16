//
//  ContactListView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

struct ContactListView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @State private var isAdding: ContactStruct?
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
                VStack(alignment: .leading) {
                    Text("Is signed in: \(vm.isSignedIntoiCloud.description)")
                    Text("Permission status: \(vm.permissionStatus.description)")
                    Text("Surname: \(vm.userName)")
                    Text("Email: \(vm.email)")
                    Text("Phone number: \(vm.telephone)")
                    Text(vm.error)
                }
                if vm.contacts.count == 0 {
                    Text("В вашем списке пока-что нет ни одного контакта 🧐\n\nНажмите '+' в правом верхнем углу, чтобы добавить ваш первый контакт.")
                        .frame(maxWidth: 550, alignment: .center)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.theme.secondaryText)
                        .padding(.top, 40)
                    
                }
                ForEach(vm.listOrder(order: filter)) { customer in
                    ZStack(alignment: .leading) {
                        ContactCellView(contact: customer)
                        NavigationLink {
                            ContactView(contact: customer)
                        } label: {
                            EmptyView()
                        }
                        .opacity(0.0)
                    }
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            isAdding = customer
                        } label: {
                            Label("Контакт", systemImage: "person.fill.checkmark")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false, content: {
                        Button {
                            if let index = vm.contacts.firstIndex(where: {$0.id == customer.id}) {
                                vm.contacts[index].isFavorite.toggle()
                            }
                        } label: {
                            Label(customer.isFavorite ? "Убрать" : "Добавить", systemImage: customer.isFavorite ? "star.slash" : "star.fill")
                        }
                        .tint(.yellow)
                    })
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: vm.deleteContactIniCloudKit)
                .onMove(perform: vm.moveContact)
            }
            .ignoresSafeArea(edges: .bottom)
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
            .frame(maxWidth: 550)
            .listStyle(.inset)
            .navigationTitle("Контакты")
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
            .alert("Фильтр контактов", isPresented: $showAlert, actions: {
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
                    Label("Назад", systemImage: "chevron.left")
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
                            vm.addMeeting(contact: isAdding!, date: date, feeling: feeling, describe: describe)
                            isAdding!.contact.lastContact = isAdding!.contact.allEvents.map{$0.date}.max()!
                            if let i = vm.contacts.firstIndex(where: {$0.id == isAdding!.id}) {
                                vm.contacts[i].contact.lastContact = isAdding!.contact.allEvents.map{$0.date}.max()!
                            }
                            isAdding = nil
                            date = Date()
                            feeling = .notTooBad
                            describe = ""
                        } label: {
                            Text("Сохранить")
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
