//
//  Helpers.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 20/02/2025.
//

import SwiftUI


func daySuffix(from date: Date) -> String {
    let day = Calendar.current.component(.day, from: date)
    switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
    }
}

func dayAndMonth(for date: Date) -> AttributedString {
    let day = Calendar.current.component(.day, from: date)
    let suffix = daySuffix(from: date)
    
    // Build the day with suffix
    var dayString = AttributedString("\(day)")
    var suffixString = AttributedString(suffix)
    
    // Make the suffix subscript
    suffixString.font = .system(size: 14) // Adjust size for the subscript
    suffixString.baselineOffset = 0      // Move it down to be subscript
    
    // Combine them
    dayString.append(suffixString)
    
    // Add the month
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    let month = formatter.string(from: date)
    dayString.append(AttributedString(" \(month)"))
    
    return dayString
}


func monthName(from monthNumber: Int) -> String {
    let dateFormatter = DateFormatter()
    return dateFormatter.monthSymbols?[monthNumber - 1] ?? "Month \(monthNumber)"
}

func formattedDate(_ date: Date) -> String {
    // Get today's and tomorrow's date without time components
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date()) // Get the start of today
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)! // Get the start of tomorrow
    
    // Strip time components from the input date
    let strippedDate = calendar.startOfDay(for: date)
    
    // Compare the stripped date to tomorrow
    if calendar.isDate(strippedDate, inSameDayAs: tomorrow) {
        return "tomorrow"
    } else if calendar.isDate(strippedDate, inSameDayAs: today) {
        return "today"
    }

    // If it's not tomorrow, return the day of the week
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter.string(from: date)
}

func formatYear(_ year: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none // No formatting, no thousand separators
    return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
}

// Helper function to get the color
func colorForBinName(_ name: String) -> Color {
    switch name {
    case "Blue":
        return .blue
    case "Brown":
        return .brown
    case "Green":
        return .green
    case "Grey":
        return .gray
    default:
        return .primary
    }
}

let locations = [
    "Bishopton",
    "Bridge of Weir",
    "Brookfield",
    "Brooklands",
    "Coatsbrae",
    "Crosslee",
    "Dargavel",
    "Houston",
    "Howwood",
    "Kilbarchan",
    "Langbank",
    "Lochwinnoch",
    "Merchiston Drive",
    "Napier Grove",
    "Weirs Wynd"
]
