//
//  AddNewContactView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI
import UIKit

struct AddNewContactView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @State private var name = ""
    @State private var selectedDate = Date()
    @Environment(\.dismiss) var dismiss
    @State private var lastMeeting = Date()
    @State private var component = Components.week
    @State private var distance = 2
    @State private var reminder = true
    @State private var feeling = Feelings.notTooBad
    @State private var describe = ""
    @State private var isFavorite = false
    @FocusState private var nameInFocus: Bool
    @FocusState private var describeInFocus: Bool
    
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
            VStack(alignment: .leading, spacing: 30) {
                mainSection
                meetingTrackerSection
                saveButton
            }
        }
        .frame(maxWidth: 550)
        .padding()
        .navigationTitle("New customer")
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(ScrollIndicatorVisibility.hidden)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.nameInFocus = true
            }
        }
        .onTapGesture(count: 2) {
            if describeInFocus {
                describeInFocus = false
            }
        }
    }
}

struct CreateCustomerView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewContactView()
            .preferredColorScheme(.dark)
            .environmentObject(ViewModel())
        AddNewContactView()
            .preferredColorScheme(.light)
            .environmentObject(ViewModel())
    }
}

extension AddNewContactView {
    var mainSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                TextField("Name", text: $name)
                    .foregroundColor(.theme.standard)
                    .textFieldStyle(.roundedBorder)
                    .focused($nameInFocus)
                    .autocorrectionDisabled()
                Button {
                    isFavorite.toggle()
                } label: {
                    ZStack {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 5)
            }
            DatePicker("Birthday:", selection: $selectedDate, in: dateRange, displayedComponents: .date)
            //                .environment(\.locale, Locale.init(identifier: "ru"))
                .foregroundColor(.theme.standard)
        }
    }
    var meetingTrackerSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            DatePicker("Last contact:", selection: $lastMeeting, in: dateRange, displayedComponents: .date)
            //                .environment(\.locale, Locale.init(identifier: "ru"))
                .foregroundColor(.theme.standard)
            VStack {
                Picker("", selection: $feeling) {
                    ForEach(Feelings.allCases, id: \.self) { feeling in
                        Text(feeling.rawValue).tag(feeling)
                    }
                }
                .pickerStyle(.segmented)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .foregroundColor(.theme.standard)
                if describeInFocus {
                    Text("To hide the keyboard double-tap on screen")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.theme.secondaryText)
                }
                TextEditor(text: $describe)
                    .focused($describeInFocus)
                    .frame(height: 100)
                    .foregroundColor(.theme.secondaryText)
                    .padding(10)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .secondarySystemFill))
                            .allowsHitTesting(false)
                    }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Contact range")
                    .foregroundColor(.theme.standard)
                HStack(spacing: 15) {
                    Picker("", selection: $distance) {
                        ForEach(1..<31) { item in
                            Text(String(item)).tag(item)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding(.horizontal, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(uiColor: .secondarySystemFill))
                    )
                    Picker("", selection: $component) {
                        ForEach(Components.allCases, id: \.hashValue) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding(.horizontal, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(uiColor: .secondarySystemFill))
                    )
                }
                .frame(height: 120)
            }
            VStack {
                Toggle("Notifications", isOn: $reminder)
                    .foregroundColor(.theme.standard)
                    .padding(.trailing, 5)
            }
        }
    }
    var saveButton: some View {
        HStack {
            Spacer()
            Button {
                vm.createContact(name: name, birthday: selectedDate, isFavorite: isFavorite, distance: distance, component: component, lastContact: lastMeeting, reminder: reminder, meetingDate: lastMeeting, meetingDescribe: describe, meetingFeeling: feeling)
                dismiss()
            } label: {
                Text("Save")
                    .bold()
                    .padding(10)
                    .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.count < 1)
            Spacer()
        }
    }
}
