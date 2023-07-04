//
//  MeetingView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

struct MeetingView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    @State var meeting: MeetingEntity
    @State var contact: ContactEntity
    @State private var date = Date()
    @State private var feeling = Feelings.notTooBad
    @State private var describe = ""
    @FocusState private var describeInFocus: Bool
    
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
                Picker("", selection: $feeling) {
                    ForEach(Feelings.allCases, id: \.self) { feeling in
                        Text(feeling.rawValue).tag(feeling)
                    }
                }
                .pickerStyle(.segmented)
                if describeInFocus {
                    Text("To hide the keyboard double-tap on screenу")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.theme.secondaryText)
                }
                TextEditor(text: $describe)
                    .focused($describeInFocus)
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
                        vm.editMeeting(contact: meeting.contact!, meeting: meeting, meetingDate: date, meetingDescribe: describe, meetingFeeling: feeling)
                        vm.updateLastContact(contact: meeting.contact!)
                        dismiss()
                    } label: {
                        Text("Save")
                            .bold()
                            .padding(10)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        vm.deleteMeetingFromMeetingView(contact: meeting.contact!, meeting: meeting)
                        vm.updateLastContact(contact: contact)
                        dismiss()
                    } label: {
                        Text("Delete")
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(maxWidth: 550)
        .padding()
        .onAppear {
            date = meeting.date!
            feeling = Feelings(rawValue: meeting.feeling!)!
            describe = meeting.describe!
        }
        .onTapGesture(count: 2) {
            if describeInFocus {
                describeInFocus = false
            }
        }
    }
}

struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingView(meeting: ViewModel().fetchedMeetings.first!, contact: ViewModel().fetchedContacts.first!)
            .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
            .environmentObject(ViewModel())
            .preferredColorScheme(.light)
        MeetingView(meeting: ViewModel().fetchedMeetings.first!, contact: ViewModel().fetchedContacts.first!)
            .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
            .environmentObject(ViewModel())
            .preferredColorScheme(.dark)
    }
}
