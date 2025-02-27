//
//  ContentView.swift
//  Renfrewshire Bin Schedule on a wrist Watch App
//
//  Created by Artur Kraft on 20/02/2025.
//

import SwiftUI


// MARK: - ContentView
struct ContentView: View {
    @AppStorage("location") private var location: String?
    @ObservedObject var controller: BinScheduleController
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    let upcoming = controller.upcomingCollections()
                    
                    if upcoming.isEmpty {
                        Text("No upcoming collections found.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        // Next Collection card
                        if let next = upcoming.first {
                            VStack {
                                VStack(alignment: .center) {
                                    // Left side: Title and date info
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(formattedDate(next.date))
                                            .font(.caption)
                                        Text(dayAndMonth(for: next.date))
                                            .font(.headline)
                                        
                                        HStack {
                                            ForEach(next.bins, id: \.self) { bin in
                                                Text(bin.displayName)
                                                    .padding(2)
                                                    .background(bin.color.opacity(0.3))
                                                    .cornerRadius(5)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Right side: Bin images
                                    HStack(spacing: 8) {
                                        ForEach(next.bins, id: \.self) { bin in
                                            Image("\(bin.rawValue)Bin")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 70)
                                        }
                                    }
                                }
                                .padding()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(backgroundGradient(for: next.bins))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Subsequent Collections list
                        if upcoming.count > 1 {
                            Text("Subsequent collections")
                                .font(.title3)
                                .bold()
                                .padding(.horizontal)
                                .padding(.top, 20)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(Array(upcoming.dropFirst())) { collection in
                                    VStack {
                                        VStack {
                                            // Left: Date info and bin labels
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(formattedDate(collection.date))
                                                    .font(.caption)
                                                Text(dayAndMonth(for: collection.date))
                                                    .font(.headline)
                                                
                                                HStack {
                                                    ForEach(collection.bins, id: \.self) { bin in
                                                        Text(bin.displayName)
                                                            .padding(6)
                                                            .background(bin.color.opacity(0.3))
                                                            .cornerRadius(5)
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Right: Bin images
                                            HStack(spacing: 8) {
                                                ForEach(collection.bins, id: \.self) { bin in
                                                    Image("\(bin.rawValue)Bin")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 60)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 30)
                                        .padding(.horizontal)
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    
                    // "Change Location" button at the bottom
                    Button("Change Location") {
                        location = nil
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical)
            }
            .navigationTitle(location ?? "Select Location")

        }
    }
    
    private func backgroundGradient(for bins: [BinType]) -> LinearGradient {
        let binColors = bins.map { $0.color.opacity(0.3) }
        let neutralColor = Color.gray.opacity(0.1)
        
        var gradientColors: [Color] = [neutralColor, neutralColor, neutralColor, neutralColor]
        gradientColors.append(contentsOf: binColors)
        
        return LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Use a dummy controller for preview purposes.
        ContentView(controller: .init(scheduleYear: 2025, location: "Crosslee"))
    }
}
