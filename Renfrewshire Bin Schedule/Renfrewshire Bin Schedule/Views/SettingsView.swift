//
//  SettingsView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI
import FirebaseAnalytics

// MARK: - SettingsView
struct SettingsView: View {
    @AppStorage("colorScheme") var colorScheme: String = "system"
    @AppStorage("location") var location: String?
    @AppStorage("weatherInfoEnabled") var weatherInfoEnabled: Bool = true // New AppStorage for weather info toggle
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openUrl
    
    @State private var showAlert = false

    
    let darkModeOptions = ["system", "light", "dark"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Color Scheme", selection: $colorScheme) {
                        ForEach(darkModeOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Weather Info")) {
                    Toggle(isOn: $weatherInfoEnabled) {
                        Text("Show Weather Info")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: weatherInfoEnabled) { oldValue, newValue in
                        // Log the toggle state in Firebase Analytics
                        let eventName = newValue ? "weather_info_enabled" : "weather_info_disabled"
                        
                        Analytics.logEvent(eventName, parameters: [
                            "status": newValue ? "on" : "off"
                        ])
                    }
                }
                
                Section(header: Text("Feedback")) {
                    Button("Open Mail") {
                        sendEmail()
                    }
                    .foregroundColor(.blue)
                }
                
                Section(header: Text("Location")) {
                    Button("Change Location") {
                        location = nil
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
                
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("There was an error"),
                    message: Text("Please go to www.bins.ren to send us an email."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            
            VStack{
                Text("Copyright ©2025 Artur Kraft. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    func sendEmail() {
        let urlString = "mailto:contact@bins.ren?subject=Feedback&body=Hello, "
        guard let url = URL(string: urlString) else { return }
        
        openUrl(url) { accepted in
            if !accepted {
                showAlert = true // Show an alert if email couldn't be opened
            }
        }
    }
}
