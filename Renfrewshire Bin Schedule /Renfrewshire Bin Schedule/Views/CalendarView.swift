//
//  CalendarView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//

import SwiftUI
import UIKit


struct CalendarView: View {
    @ObservedObject var controller: BinScheduleController
    
    var body: some View {
        ScrollView {
            VStack {
                UIKitCalendarView(controller: controller)
                    .frame(maxWidth: .infinity) // Use full width
                    .frame(height: 600) // Explicit height to ensure visibility
                    .padding(.horizontal, 15)
                    .clipShape(RoundedRectangle(cornerRadius: 50))
                    .shadow(radius: 2)
            }
            .padding(.vertical, 10)
        }
//        .background(Color(.systemGray6))
    }
}



