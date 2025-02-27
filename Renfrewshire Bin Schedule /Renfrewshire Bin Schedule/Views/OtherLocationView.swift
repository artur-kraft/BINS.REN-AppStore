//
//  OtherLocationView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI

struct OtherLocationView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openUrl
    
    @State private var showAlert = false

    var body: some View {
        Form {
            Section(header: Text("Other Location Request")) {
                Text("I am consistently adding more locations. If your location is not listed yet, please send me your address (or at least a post code) and I will try to add it. I am working on this app in my spare time and currently I focus on villages, estates and areas that all have the same schedule. Please don't request bigger towns like Paisley, Renfrew, or Johnstone, there are too many variables there. I am trying to add parts of them first.")
                    .font(.subheadline)
            }
            
            Section {
                Button("Send Email") {
                    sendEmail()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Other Location")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("There was an error"),
                message: Text("Please go to www.bins.ren to send us an email."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    func sendEmail() {
        let urlString = "mailto:contact@bins.ren?subject=Other Location&body=Hi there! Can you please add the following location location to the Renfrewshire bins app: "
        guard let url = URL(string: urlString) else { return }
        
        openUrl(url) { accepted in
            if !accepted {
                showAlert = true // Show an alert if email couldn't be opened
            }
        }
    }
}

struct OtherLocationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OtherLocationView()
        }
    }
}
