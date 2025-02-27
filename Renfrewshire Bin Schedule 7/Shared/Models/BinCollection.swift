//
//  BinCollection.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import Foundation

// MARK: - BinCollection Model
struct BinCollection: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bins: [BinType]
    
    // Custom initializer that generates a new id.
    init(date: Date, bins: [BinType]) {
        self.id = UUID()
        self.date = date
        self.bins = bins
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case date, bins
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try container.decode(Date.self, forKey: .date)
        self.bins = try container.decode([BinType].self, forKey: .bins)
        // Generate a new id rather than decoding one.
        self.id = UUID()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(bins, forKey: .bins)
    }
}
