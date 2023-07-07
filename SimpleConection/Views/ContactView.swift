//
//  ContactView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

struct ContactView: View {
    
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @State var contact: ContactEntity
    @State private var isEditing = false
    @State private var name = ""
    @State private var isAdding = false
    @State private var date = Date()
    @State private var feeling = Feelings.notTooBad
    @State private var describe = ""
    @State private var isFavorite = false
    @State private var meetingSheet: MeetingEntity? = nil
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
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
                Button("Edit") {
                    isEditing.toggle()
                }
                .disabled(name.count < 3)
            }
        }
        .sheet(isPresented: $isEditing, content: {
            ChangeContactView(contact: $contact)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.7), .large])
        })
        .sheet(isPresented: $isAdding, content: {
            addMeetingSheet
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.7), .large])
        })
        .sheet(item: $meetingSheet, content: { meeting in
            MeetingView(meeting: meeting, contact: contact)
                .presentationDragIndicator(.visible)
        })
        .onAppear {
            vm.fetchedMeetings.removeAll()
            vm.getMeetingsOfContact(forContact: contact)
            name = contact.name!
            isFavorite = contact.isFavorite
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContactView(contact: ViewModel().fetchedContacts.first!)
                .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
                .preferredColorScheme(.dark)
        }
        .environmentObject(ViewModel())
        NavigationStack {
            ContactView(contact: ViewModel().fetchedContacts.first!)
                .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
                .preferredColorScheme(.light)
        }
        .environmentObject(ViewModel())
    }
}

extension ContactView {
    var titleSection: some View {
        VStack(spacing: 15) {
            VStack {
                Text(contact.name!)
                    .font(.title)
                    .foregroundColor(.theme.standard)
            }
            VStack(spacing: 5) {
                Text("Last contact: \(dateFormatter.string(from: contact.lastContact ?? Date()))")
                Text(vm.daysFromLastEvent(lastEvent: contact.lastContact ?? Date(), component: Components(rawValue: contact.component!) ?? .day, Interval: Int(contact.distance)))
            }
            .font(.callout)
            .foregroundColor(vm.getNextEventDate(component: Components(rawValue: contact.component!) ?? .day, lastContact: contact.lastContact ?? Date(), interval: Int(contact.distance)) > Date() ? .theme.green : .theme.red)
            ZStack {
                Button {
                    isFavorite.toggle()
                    vm.toggleFavorite(contact: self.contact)
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
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            .padding(.top, 5)
            }
        }
        .padding(.top, 20)
    }
    
    var eventsSection: some View {
        ForEach(vm.fetchedMeetings) { meeting in
            Button {
                meetingSheet = meeting
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
                        vm.createMeeting(contact: contact, meetingDate: date, meetingDescribe: describe, meetingFeeling: feeling)
                        isAdding.toggle()
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
