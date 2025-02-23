//
//  UpcomingCollectionsView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI
import CoreLocation

// MARK: - UpcomingCollectionsView
struct UpcomingCollectionsView: View {
    @ObservedObject var controller: BinScheduleController

    var body: some View {
        NavigationStack {
            ScrollView {
                let upcoming = controller.upcomingCollections()
                VStack(alignment: .leading, spacing: 20) {
                    if upcoming.isEmpty {
                        Text("No upcoming collections found.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        if let next = upcoming.first {
                            NextCollectionCard(collection: next)
                        }
                        if upcoming.count > 1 {
                            SubsequentCollectionsList(collections: Array(upcoming.dropFirst()))
                        }
                    }
                    Spacer()
                }
                .padding(.vertical)
            }
        }
    }
}

struct NextCollectionCard: View {
    var collection: BinCollection
    @State private var weatherManager = WeatherManager()
    @AppStorage("weatherInfoEnabled") var weatherInfoEnabled: Bool = true
    @Environment(\.horizontalSizeClass) var sizeClass
    
    let brookfield = CLLocation(latitude: 55.847094, longitude: -4.530314)

    var body: some View {
        VStack {
            Text("Next collection")
                .font(sizeClass == .regular ? .largeTitle : .title) // Larger title for iPad
                .bold()
                .padding(.horizontal)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center) {
                // Left side: bin label and date info
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedDate(collection.date))
                        .font(sizeClass == .regular ? .title3 : .caption) // Adjusted for iPad
                    Text(dayAndMonth(for: collection.date))
                        .font(sizeClass == .regular ? .title : .headline) // Adjusted for iPad
                    
                    HStack {
                        ForEach(collection.bins, id: \.self) { bin in
                            Text(bin.displayName)
                                .font(sizeClass == .regular ? .body : .caption2)
                                .padding(5)
                                .background(bin.color.opacity(0.3))
                                .cornerRadius(5)
                        }
                    }
                    
                    if weatherInfoEnabled {
                        VStack(spacing: 3) {
                            Image(systemName: weatherManager.icon)
                                .font(sizeClass == .regular ? .largeTitle : .title)
                                .shadow(radius: 4)
                                .padding(0)
                            Text("Temperature: \(weatherManager.temperature)")
                                .font(sizeClass == .regular ? .title3 : .caption)
                            Text("Wind gust: \(weatherManager.windGust)")
                                .font(sizeClass == .regular ? .title3 : .caption)
                            Text("\(weatherManager.precipitationType) chance: \(weatherManager.rainProbability)")
                                .font(sizeClass == .regular ? .title3 : .caption)
                            Text(" Weather")
                                .font(sizeClass == .regular ? .title3 : .caption)
                        }
                        .onAppear {
                            Task {
                                await weatherManager.getWeather(lat: brookfield.coordinate.latitude,
                                                                long: brookfield.coordinate.longitude,
                                                                for: collection.date)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Right side: Bin images
                HStack(spacing: 3) {
                    ForEach(collection.bins, id: \.self) { bin in
                        Image("\(bin.rawValue)Bin")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: sizeClass == .regular ? 120 : 90) // Larger for iPad
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundGradient(for: collection.bins))
        .cornerRadius(12)
        .padding(.horizontal, sizeClass == .regular ? 40 : 20) // More side padding on iPad
    }
}


struct SubsequentCollectionsList: View {
    var collections: [BinCollection]
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("weatherInfoEnabled") var weatherInfoEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subsequent collections")
                .font(sizeClass == .regular ? .title : .title2) // Larger title for iPad
                .bold()
                .padding(.horizontal, sizeClass == .regular ? 40 : 20) // More side padding on iPad
                .padding(.top, sizeClass == .regular ? 60 : 50)
            
            ForEach(collections) { collection in
                VStack {
                    HStack {
                        // Left: Date info and bin labels
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate(collection.date))
                                .font(sizeClass == .regular ? .title3 : .caption) // Adjusted for iPad
                            Text(dayAndMonth(for: collection.date))
                                .font(sizeClass == .regular ? .title2 : .headline) // Adjusted for iPad
                            
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
                        
                        Spacer()
                        
                        // Right: Bin images
                        HStack(spacing: 3) {
                            ForEach(collection.bins, id: \.self) { bin in
                                Image("\(bin.rawValue)Bin")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: sizeClass == .regular ? 90 : 60) // Larger for iPad
                            }
                        }
                    }
                    .padding(.vertical, sizeClass == .regular ? 40 : 30)
                    .padding(.horizontal, sizeClass == .regular ? 40 : 20) // More padding on iPad
                    Divider()
                }
            }
            if weatherInfoEnabled {
                Link("* weather data sources",
                     destination: URL(string: "https://developer.apple.com/weatherkit/data-source-attribution/")!)
                .padding(.horizontal)
                .font(.caption)
            }
            
        }
        
    }
}


// MARK: - Helper Functions

func backgroundGradient(for bins: [BinType]) -> LinearGradient {
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

struct UpcomingCollections_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingCollectionsView(controller: BinScheduleController(scheduleYear: 2025, location: "Crosslee"))
    }
}
