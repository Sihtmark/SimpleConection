//
//  ContactView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

struct ContactView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MeetingEntity.date, ascending: true)], animation: .default)
    var fetchedMeetings: FetchedResults<MeetingEntity>
    
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @State var contact: ContactEntity
    @State private var isEditing = false
    @State private var name = ""
    @State private var selectedDate = Date()
    @State private var isAdding = false
    @State private var date = Date()
    @State private var feeling = Feelings.notTooBad
    @State private var describe = ""
    @State private var isFavorite = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }
    
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
        ScrollView {
            titleSection
            eventsSection
        }
        .ignoresSafeArea(edges: .bottom)
        .scrollIndicators(ScrollIndicatorVisibility.hidden)
        .frame(maxWidth: 550)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Сохранить" : "Изменить") {
                    isEditing.toggle()
                }
                .disabled(name.count < 3)
            }
        }
        .sheet(isPresented: $isEditing, content: {
            ChangeContactView(contact: $contact)
        })
        .sheet(isPresented: $isAdding, content: {
            addMeetingSheet
        })
        .onAppear {
            name = contact.name!
            selectedDate = contact.birthday!
            isFavorite = contact.isFavorite
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContactView(contact: ViewModel().fetchedContacts.first!)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .preferredColorScheme(.dark)
        }
        .environmentObject(ViewModel())
        NavigationStack {
            ContactView(contact: ViewModel().fetchedContacts.first!)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .preferredColorScheme(.light)
        }
        .environmentObject(ViewModel())
    }
}

extension ContactView {
    var titleSection: some View {
        VStack(spacing: 15) {
//            NavigationLink {
//                ContactInfoView(contact: contact)
//            } label: {
//                ZStack {
//                    Circle()
//                        .fill(.white)
//                        .frame(width: 80)
//                        .shadow(radius: 3)
//                    Circle()
//                        .fill(Color(uiColor: .secondarySystemFill))
//                        .frame(width: 77)
//                    Image("\(contact.annualSignStruct.annualSign)")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 45, height: 45)
//                }
//            }
            VStack {
                Text(contact.name!)
                    .font(.title)
                    .foregroundColor(.theme.standard)
            }
            VStack(spacing: 5) {
                Text("Последнее общение \(dateFormatter.string(from: contact.lastContact ?? Date()))")
                Text(vm.daysFromLastEvent(lastEvent: contact.lastContact ?? Date()))
            }
            .font(.callout)
            .foregroundColor(vm.getNextEventDate(component: Components(rawValue: contact.component!)!, lastContact: contact.lastContact ?? Date(), interval: Int(contact.distance)) > Date() ? .theme.green : .theme.red)
            ZStack {
                Button {
                    isFavorite.toggle()
                    vm.toggleFavorite(contact: self.contact, isFavorite: isFavorite, context: moc)
                } label: {
                    ZStack {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
                .offset(x: 100)
                Button {
                    isAdding.toggle()
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            .padding(.top, 5)
            }
        }
        .padding(.top, 20)
    }
    
    var eventsSection: some View {
        ForEach(fetchedMeetings.filter({$0.contact == contact})) { meeting in
            NavigationLink {
                MeetingView(meeting: meeting)
            } label: {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.theme.accent, lineWidth: 0.4)
                        .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack() {
                            Text(meeting.feeling!)
                            Text(dateFormatter.string(from: meeting.date!))
                                .foregroundColor(.theme.accent)
                        }
                        Text(meeting.describe!)
                            .foregroundColor(.theme.secondaryText)
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
            }
        }
    }
    
    var addMeetingSheet: some View {
        VStack {
            HStack {
                Button {
                    isAdding.toggle()
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
                            vm.createMeeting(contact: contact, meetingDate: date, meetingDescribe: describe, meetingFeeling: feeling, context: moc)
//                            contact = contact.addMeeting(contact: contact.contact, date: date, feeling: feeling, describe: describe)
                            vm.updateLastContact(contact: contact, context: moc)
                            isAdding.toggle()
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
