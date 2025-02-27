//
//  ListView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//

import SwiftUI

// MARK: - ListView
struct ListView: View {
    @ObservedObject var controller: BinScheduleController
    @State private var upcomingCollectionID: UUID?
    @Environment(\.horizontalSizeClass) var sizeClass

    var groupedCollections: [String: [BinCollection]] {
        Dictionary(grouping: controller.collections, by: {
            "\(controller.calendar.component(.year, from: $0.date))-\(controller.calendar.component(.month, from: $0.date))"
        })
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(groupedCollections.keys.sorted(by: sortKeys), id: \.self) { key in
                    let collections = groupedCollections[key] ?? []
                    
                    if !collections.isEmpty {
                        let month = controller.calendar.component(.month, from: collections[0].date)
                        let year = controller.calendar.component(.year, from: collections[0].date)
                        let formattedYear = formatYear(year)
                        
                        Section(header: Text("\(monthName(from: month)) \(formattedYear)")
                            .font(sizeClass == .regular ? .title : .headline) // Larger header on iPad
                            .padding(.horizontal, sizeClass == .regular ? 40 : 20)
                        ) {
                            ForEach(collections) { collection in
                                HStack {
                                    VStack(alignment: .leading) {
                                        if collection.id == upcomingCollectionID {
                                            Text("🔽 Next collection:")
                                                .font(sizeClass == .regular ? .title3 : .headline)
                                                .foregroundColor(Color.orange)
                                        }
                                        Text("\(dayAndMonth(for: collection.date))")
                                            .font(sizeClass == .regular ? .title2 : .headline)
//                                            .foregroundColor(collection.id == upcomingCollectionID ? Color.orange : .primary)
                                        
                                        Text("\(formattedDate(collection.date))")
                                            .font(sizeClass == .regular ? .title3 : .subheadline)
//                                            .foregroundColor(collection.id == upcomingCollectionID ? Color.orange : .secondary)
                                    }
                                    Spacer()
                                    
                                    // Bin Labels
                                    HStack {
                                        ForEach(collection.bins, id: \.self) { bin in
                                            Text(bin.displayName)
                                                .font(sizeClass == .regular ? .body : .caption)
                                                .padding(6)
                                                .background(bin.color.opacity(0.3))
                                                .cornerRadius(5)
                                        }
                                    }
                                }
                                .padding(.vertical, sizeClass == .regular ? 15 : 5)
                                .padding(.horizontal, sizeClass == .regular ? 40 : 20)
                                .id(collection.id)
                            }
                        }
                    }
                }
            }
            .onAppear {
                findUpcomingCollection()
                if let upcomingID = upcomingCollectionID {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        proxy.scrollTo(upcomingID, anchor: .top)
                    }
                }
            }
        }
    }

    
    // MARK: - Helper Functions
    func sortKeys(_ lhs: String, _ rhs: String) -> Bool {
        let lhsComponents = lhs.split(separator: "-").compactMap { Int($0) }
        let rhsComponents = rhs.split(separator: "-").compactMap { Int($0) }
        return lhsComponents.lexicographicallyPrecedes(rhsComponents)
    }

    func findUpcomingCollection() {
        if let nextCollection = controller.collections.first(where: {
            controller.calendar.isDate($0.date, inSameDayAs: Date()) || $0.date > Date()
        }) {
            upcomingCollectionID = nextCollection.id
        }
    }

    

    

    

}
