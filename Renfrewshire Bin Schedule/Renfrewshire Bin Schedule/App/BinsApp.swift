//
//  BinsApp.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseAnalytics


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Do not show notifications when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([]) // No banner, sound, or badge
    }
}


// MARK: - App Entry Point
@main
struct BinsApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("location") private var location: String?
    
    init() {
        formatNavTitle(15, 35)
        requestNotificationAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            if let loc = location {
                ContentView(location: loc)
            } else {
                WelcomeView()
            }
        }
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
}

func formatNavTitle(_ fontSize: CGFloat, _ largeFontSize: CGFloat) {

    let appearance = UINavigationBarAppearance()
    
    appearance.largeTitleTextAttributes = [
        .font : UIFont.systemFont(ofSize: largeFontSize),
        NSAttributedString.Key.foregroundColor : UIColor.label
    ]
    
    appearance.titleTextAttributes = [
        .font : UIFont.systemFont(ofSize: fontSize),
        NSAttributedString.Key.foregroundColor : UIColor.label
    ]
    
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().tintColor = .label
}

struct UpdateAlertModifier: ViewModifier {
    @State private var showUpdateAlert = false
    @State private var appStoreURL: URL?
    
    func body(content: Content) -> some View {
        content
            .onAppear(perform: checkForUpdate)
            .alert("New Version Available", isPresented: $showUpdateAlert) {
                Button("Update") {
                    if let url = appStoreURL {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Later", role: .cancel) {
                    // Log the "Later" button press event in Firebase Analytics
                    Analytics.logEvent("update_later_pressed", parameters: [
                        "button": "Later"
                    ])
                }
            } message: {
                Text("A new version of the app is available. Please update to the latest version.")
            }
    }
    
    private func checkForUpdate() {
        AppVersionChecker.isNewVersionAvailable { isAvailable, url in
            if isAvailable {
                appStoreURL = url
                showUpdateAlert = true
                // Log the event to Firebase Analytics
                Analytics.logEvent("new_version_available", parameters: nil)
            }
        }
    }
}

extension View {
    func showUpdateAlert() -> some View {
        self.modifier(UpdateAlertModifier())
    }
}






