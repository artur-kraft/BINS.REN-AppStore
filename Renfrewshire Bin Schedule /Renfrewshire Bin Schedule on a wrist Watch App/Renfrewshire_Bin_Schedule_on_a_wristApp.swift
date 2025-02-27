//
//  Renfrewshire_Bin_Schedule_on_a_wristApp.swift
//  Renfrewshire Bin Schedule on a wrist Watch App
//
//  Created by Artur Kraft on 20/02/2025.
//

import SwiftUI


@main
struct Renfrewshire_Bin_Schedule_on_a_wrist_Watch_AppApp: App {
    @AppStorage("location") private var location: String?
    
    var body: some Scene {
        WindowGroup {
            if location != nil {
                ContentView(controller: .init(scheduleYear: 2025, location: location!))
            } else {
                LocationSelectionView()
            }
        }
    }
}
