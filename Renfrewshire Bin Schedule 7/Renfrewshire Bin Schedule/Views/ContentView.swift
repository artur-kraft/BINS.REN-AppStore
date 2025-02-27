//
//  ContentView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI
import FirebaseAnalytics

// MARK: - ContentView
struct ContentView: View {
    var location: String
    @StateObject var controller: BinScheduleController
        
    init(location: String) {
        self.location = location
        _controller = StateObject(wrappedValue: BinScheduleController(scheduleYear: 2025, location: location))
    }
    
    @AppStorage("colorScheme") var colorScheme: String = "system"
    @AppStorage("themeColor") var themeColor: String = "Blue" // New AppStorage property
    
    @State private var showingSettings = false
    
    var preferredScheme: ColorScheme? {
        switch colorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    
    // Map the stored themeColor string to a SwiftUI Color.
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
            TabView {
                UpcomingCollectionsView(controller: controller)
                    .tabItem {
                        Label("Upcoming", systemImage: "clock")
                    }
                    .onAppear {
                        logNavigationChange(for: "Upcoming Collections View")
                    }
                    .onDisappear {
                        logNavigationChange(for: "Upcoming Collections View", isAppearing: false)
                    }
                
                ListView(controller: controller)
                    .tabItem {
                        Label("List", systemImage: "list.bullet")
                    }
                    .onAppear {
                        logNavigationChange(for: "List View")
                    }
                    .onDisappear {
                        logNavigationChange(for: "List View", isAppearing: false)
                    }
                
                CalendarView(controller: controller)
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .onAppear {
                        logNavigationChange(for: "Calendar View")
                    }
                    .onDisappear {
                        logNavigationChange(for: "Calendar View", isAppearing: false)
                    }
                
                InfoView()
                    .tabItem {
                        Label("Info", systemImage: "info.circle")
                    }
                    .onAppear {
                        logNavigationChange(for: "Info View")
                    }
                    .onDisappear {
                        logNavigationChange(for: "Info View", isAppearing: false)
                    }
            }
            .accentColor(accent)  // Apply the theme color as the accent
            .navigationTitle("🏡 \(location)")
            .showUpdateAlert()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            if #available(iOS 18.0, *) {
                SettingsView()
            } else {
                // Fallback for earlier iOS versions: Present the same SettingsView (or adjust if needed)
                SettingsView()
            }
        }
        .preferredColorScheme(preferredScheme)
    }
    
    func logNavigationChange(for viewName: String, isAppearing: Bool = true) {
        let eventName = isAppearing ? "view_appeared" : "view_disappeared"
        Analytics.logEvent(eventName, parameters: [
            "view_name": viewName,
            "status": isAppearing ? "appeared" : "disappeared"
        ])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(location: "Crosslee")
    }
}
