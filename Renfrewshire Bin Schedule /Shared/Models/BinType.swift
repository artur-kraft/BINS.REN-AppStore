//
//  BinType.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI

extension UIColor {
    static var mySystemGray5: UIColor {
        return .init(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
    }
    static var mySystemBlue: UIColor {
        return .init(red: 59/255, green: 130/255, blue: 247/255, alpha: 1)
    }
    static var mySystemGreen: UIColor {
        return .init(red: 104/255, green: 206/255, blue: 103/255, alpha: 1)
    }
    static var mySystemBrown: UIColor {
        return .init(red: 143/255, green: 81/255, blue: 27/255, alpha: 1)
    }
}

enum BinType: String, CaseIterable, Identifiable, Codable {
    case blue, brown, grey, green
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .brown: return "Brown"
        case .grey: return "Grey"
        case .green: return "Green"
        }
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .brown: return Color(red: 0.6, green: 0.3, blue: 0.0)
        case .grey: return .gray
        case .green: return .green
        }
    }
    
    /// Convert the SwiftUI Color to a UIColor.
    var uiColor: UIColor {
        switch self {
        case .blue: return UIColor.mySystemBlue
        case .brown: return UIColor.mySystemBrown
        case .grey: return UIColor.mySystemGray5
        case .green: return UIColor.mySystemGreen
        }
    }
}


struct Bin: Identifiable {
    var id = UUID()
    var name: String
    var imageName: String // Image name instead of color
    var itemsAllowed: [String]
    var itemsNotAllowed: [String]
    
    // Conform to Equatable by implementing the == operator
    static func ==(lhs: Bin, rhs: Bin) -> Bool {
        return lhs.id == rhs.id // Compare by unique ID
    }
}

