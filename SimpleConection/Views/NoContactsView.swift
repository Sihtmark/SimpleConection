//
//  NoContactsView.swift
//  SimpleConection
//
//  Created by Sergei Poluboiarinov on 7/7/23.
//

import SwiftUI

struct NoContactsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @State var animate = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("There are no contacts")
                    .font(.title)
                    .fontWeight(.semibold)
                Text(vm.noContactsText(order: vm.contactsOrder))
                    .padding(.bottom, 15)
                NavigationLink {
                    AddNewContactView()
                } label: {
                    Text("Add contact 🥳")
                        .foregroundColor(.white)
                        .font(.headline)
                        .scaleEffect(animate ? 1.1 : 1.0)
                        .frame(height: animate ? 55 : 45)
                        .frame(maxWidth: .infinity)
                        .background(animate ? Color.theme.red : Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal, animate ? 30 : 50)
                .shadow(
                    color: animate ? .theme.red.opacity(0.7) : Color.accentColor.opacity(0.7),
                    radius: animate ? 30 : 10,
                    x: 0,
                    y: animate ? 50 : 30
                )
                .scaleEffect(animate ? 1.1 : 1.0)
                .offset(y: animate ? -7 : 0)
            }
            .frame(maxWidth: 400)
            .multilineTextAlignment(.center)
            .padding(40)
            .onAppear(perform: addAnimation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct NoContactsView_Previews: PreviewProvider {
    static var previews: some View {
        NoContactsView()
    }
}
