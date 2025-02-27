//
//  SettingsView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI
import FirebaseAnalytics

struct SettingsView: View {
    // Keep other @AppStorage properties as they are, since they don’t cause issues
    @AppStorage("colorScheme") var colorScheme: String = "system"
    @AppStorage("location") var location: String?
    @AppStorage("weatherInfoEnabled") var weatherInfoEnabled: Bool = true
    @AppStorage("hasDonated") var hasDonated: Bool = false
    @AppStorage("themeColor") var themeColor: String = "Blue"
    
    // Replace @AppStorage with @State for notificationTime
    @State private var notificationTime: Date

    let themeColorOptions = ["Blue", "Red", "Green", "Purple"]
    let darkModeOptions = ["system", "light", "dark"]

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openUrl
    @State private var showAlert = false

    // Initialize notificationTime with a default value if not already set in UserDefaults
    init() {
        let calendar = Calendar.current
        let defaultTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        if let storedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            // If a value exists in UserDefaults, use it to initialize the @State variable
            _notificationTime = State(initialValue: storedTime)
        } else {
            // If no value exists, set the default and store it in UserDefaults
            _notificationTime = State(initialValue: defaultTime)
            UserDefaults.standard.set(defaultTime, forKey: "notificationTime")
        }
    }

    var accent: Color {
        switch themeColor {
        case "Blue": return .blue
        case "Red": return .red
        case "Green": return .green
        case "Purple": return .purple
        default: return .blue
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
                
                Section(header: Text("Notifications")) {
                    DatePicker(
                        "Notification Time",
                        selection: $notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .accentColor(accent)
                    .foregroundColor(hasDonated ? .primary : .secondary) // Gray out text when disabled
                    .onChange(of: notificationTime) {
                        UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
                        NotificationCenter.default.post(name: NSNotification.Name("notificationTimeDidChange"), object: nil)
                    }
                    if !hasDonated {
                        Text("Donate any amount to change this value!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!hasDonated)

                Section(header: Text("Ball Minigame")) {
                    NavigationLink(destination: BallMinigameView()) {
                        Label("Ball Minigame", systemImage: "gamecontroller.fill")
                    }
                    if !hasDonated {
                        Text("Donate any amount to unlock this minigame!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!hasDonated)

                Section(header: Text("App Accent Colour")) {
                    Picker("App Accent Colour", selection: $themeColor) {
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
                }
                .disabled(!hasDonated)

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
