//
//  SettingsView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI
import FirebaseAnalytics

struct SettingsView: View {
    @AppStorage("colorScheme") var colorScheme: String = "system"
    @AppStorage("location") var location: String?
    @AppStorage("weatherInfoEnabled") var weatherInfoEnabled: Bool = true
    @AppStorage("hasDonated") var hasDonated: Bool = false
    @AppStorage("themeColor") var themeColor: String = "Blue" // Stored theme color
    
    // Available theme color options
    let themeColorOptions = ["Blue", "Red", "Green", "Purple"]
    let darkModeOptions = ["system", "light", "dark"]
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openUrl
    @State private var showAlert = false
    
    // Computed property that maps the stored themeColor to a SwiftUI Color.
    var accent: Color {
        switch themeColor {
        case "Blue":
            return .blue
        case "Red":
            return .red
        case "Green":
            return .green
        case "Purple":
            return .purple
        default:
            return .blue
        }
    }
    
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
                    .accentColor(accent)
                }
                
                Section(header: Text("Weather Forecast")) {
                    Toggle(isOn: $weatherInfoEnabled) {
                        Text("Show Weather Forecast")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: accent))
                    .onChange(of: weatherInfoEnabled) { oldValue, newValue in
                        let eventName = newValue ? "weather_info_enabled" : "weather_info_disabled"
                        Analytics.logEvent(eventName, parameters: [
                            "status": newValue ? "on" : "off"
                        ])
                    }
                }
                
                Section(header: Text("Support the App")) {
                    NavigationLink(destination: TipJarView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(accent)
                            Text("Tip Jar")
                        }
                    }
                }
                
                Section(header: Text("Ball Minigame")) {
                    NavigationLink(destination: BallMinigameView()) {
                        Label("Ball Minigame", systemImage: "gamecontroller.fill")
                    }
                    .disabled(!hasDonated)
                    
                    if !hasDonated {
                        Text("Donate any amount to unlock this minigame!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("App Theme Colour")) {
                    Picker("App Theme Colour", selection: $themeColor) {
                        ForEach(themeColorOptions, id: \.self) { color in
                            Text(color)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accentColor(accent)
                    if !hasDonated {
                        Text("Donate any amount to unlock this function!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }.disabled(!hasDonated)
                
                
                Section(header: Text("Feedback")) {
                    Button("Open Mail") {
                        sendEmail()
                    }
                    .foregroundColor(accent)
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
            
            VStack {
                Text("Copyright ©2025 Artur Kraft. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        // Apply the accent color to the entire navigation stack.
        .accentColor(accent)
    }
    
    func sendEmail() {
        let urlString = "mailto:contact@bins.ren?subject=Feedback&body=Hello, "
        guard let url = URL(string: urlString) else { return }
        
        openUrl(url) { accepted in
            if !accepted {
                showAlert = true
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
