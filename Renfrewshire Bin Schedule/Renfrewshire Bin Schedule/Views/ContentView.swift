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
            .navigationTitle("🏡 \(location)")
            .showUpdateAlert()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
//        .overlay(
//            VStack {
//                HStack {
//                    Text("Location: \(location)")
//                        .font(.caption)
//                        .padding(6)
//                        .background(Color.secondary.opacity(0.2))
//                        .cornerRadius(8)
//                    Spacer()
//                }
//                Spacer()
//            }
//            .padding()
//        )
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
