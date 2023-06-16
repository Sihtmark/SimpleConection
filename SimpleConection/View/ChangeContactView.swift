//
//  ChangeContactView.swift
//  OnTuchRussian
//
//  Created by Sergei Poluboiarinov on 10.06.2023.
//

import SwiftUI

struct ChangeContactView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Binding var contact: ContactStruct
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedDate = Date()
    @State private var lastMeeting = Date()
    @State private var component = Components.week
    @State private var distance = 2
    @State private var reminder = true
    @State private var feeling = Feelings.notTooBad
    @State private var describe = ""
    @FocusState private var inFocus: Bool
    
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
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Назад", systemImage: "chevron.left")
                }
                Spacer()
            }
            .padding(.top, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    mainSection
                    meetingTrackerSection
                    saveButton
                    Spacer()
                }
            }
        }
        .onAppear {
            name = contact.name
            selectedDate = contact.birthday
            lastMeeting = contact.contact.lastContact
            component = contact.contact.component
            distance = contact.contact.distance
            reminder = contact.contact.reminder
        }
        .frame(maxWidth: 550)
        .padding()
        .navigationTitle("Новый пользователь")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                
            }
        }
        .onTapGesture(count: 2) {
            if inFocus {
                inFocus = false
            }
        }
    }
}

struct ChangeContactView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChangeContactView(contact: .constant(sampleContact))
                .preferredColorScheme(.dark)
        }
        .environmentObject(ViewModel())
        NavigationStack {
            ChangeContactView(contact: .constant(sampleContact))
                .preferredColorScheme(.light)
        }
        .environmentObject(ViewModel())
    }
}

extension ChangeContactView {
    var mainSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            TextField("Имя", text: $name)
                .foregroundColor(.theme.standard)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            DatePicker("День рождения:", selection: $selectedDate, in: dateRange, displayedComponents: .date)
                .environment(\.locale, Locale.init(identifier: "ru"))
                .foregroundColor(.theme.standard)
        }
    }
    var meetingTrackerSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            if contact.contact.allEvents.isEmpty {
                DatePicker("Последнее общение:", selection: $lastMeeting, in: dateRange, displayedComponents: .date)
                    .environment(\.locale, Locale.init(identifier: "ru"))
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
                    Text("Заметки или описание встречи:")
                        .foregroundColor(.theme.standard)
                    if inFocus {
                        Text("Дважды коснитесь экрана в свободном месте чтобы убрать клавиатуру")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.theme.secondaryText)
                    }
                    TextEditor(text: $describe)
                        .frame(height: 100)
                        .foregroundColor(.theme.secondaryText)
                        .padding(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(uiColor: .secondarySystemFill))
                                .allowsHitTesting(false)
                        }
                }
            }
            VStack(spacing: 5) {
                Text("Как часто хотите общаться?")
                    .font(.headline)
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
                Toggle("Напоминание когда придет время снова общаться с этим контактом", isOn: $reminder)
                    .foregroundColor(.theme.standard)
                .padding(.trailing, 5)
            }
        }
    }
    var saveButton: some View {
        HStack {
            Spacer()
            Button {
                vm.updateContact(client: contact, name: name, birthday: selectedDate, isFavorite: contact.isFavorite, distance: distance, component: component, lastContact: lastMeeting, reminder: reminder, feeling: feeling, describe: describe)
                contact = contact.updateInfo(name: name, birthday: selectedDate, isFavorite: contact.isFavorite, distance: distance, component: component, reminder: reminder)
                if reminder {
                    vm.setNotification(contactStruct: contact)
                } else {
                    vm.deleteNotification(contactStruct: contact)
                }
                dismiss()
            } label: {
                Text("Сохранить")
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