//
//  UpcomingCollectionsView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//

import SwiftUI
import CoreLocation
import WeatherKit

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
                            .transition(.opacity)
                    } else {
                        if let next = upcoming.first {
                            NextCollectionCard(collection: next)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        if upcoming.count > 1 {
                            SubsequentCollectionsList(collections: Array(upcoming.dropFirst()))
                                .transition(.opacity)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical)
                // Animate changes to the collections
                .animation(.easeInOut(duration: 0.5), value: controller.collections.count)

            }
        }
    }
}

// MARK: - NextCollectionCard
struct NextCollectionCard: View {
    var collection: BinCollection
    @State private var weatherManager = WeatherManager()
    @AppStorage("weatherInfoEnabled") var weatherInfoEnabled: Bool = true
    @Environment(\.horizontalSizeClass) var sizeClass
    let brookfield = CLLocation(latitude: 55.847094, longitude: -4.530314)
    
    // Attribution state variables
    @State private var attributionLink: URL? = nil
    @State private var legalAttributionText: String = ""
    
    // For a scaling animation
    @State private var scale: CGFloat = 0.95

    var body: some View {
        VStack {
            Text("Next collection")
                .font(sizeClass == .regular ? .largeTitle : .title)
                .bold()
                .padding(.horizontal)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center) {
                // Left side: bin label and date info
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedDate(collection.date))
                        .font(sizeClass == .regular ? .title3 : .caption)
                    Text(dayAndMonth(for: collection.date))
                        .font(sizeClass == .regular ? .title : .headline)
                    
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
                            Text("Temperature: \(weatherManager.temperature)")
                                .font(sizeClass == .regular ? .title3 : .caption)
                            Text("Wind gust: \(weatherManager.windGust)")
                                .font(sizeClass == .regular ? .title3 : .caption)
                            Text("\(weatherManager.precipitationType) chance: \(weatherManager.rainProbability)")
                                .font(sizeClass == .regular ? .title3 : .caption)
                            Text(" Weather")
                                .font(.caption)
                            
                            if let attributionLink = attributionLink, !legalAttributionText.isEmpty {
                                Link(legalAttributionText, destination: attributionLink)
                                    .font(.caption)
                            }
                        }
                        .onAppear {
                            Task {
                                if let attribution = try? await WeatherService.shared.attribution {
                                    attributionLink = attribution.legalPageURL
                                    legalAttributionText = "Other data sources"
                                }
                                await weatherManager.getWeather(
                                    lat: brookfield.coordinate.latitude,
                                    long: brookfield.coordinate.longitude,
                                    for: collection.date
                                )
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
                            .frame(width: sizeClass == .regular ? 120 : 90)
                    }
                }
            }
            .padding()
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundGradient(for: collection.bins))
        .cornerRadius(12)
        .padding(.horizontal, sizeClass == .regular ? 40 : 20)
    }
}

// MARK: - SubsequentCollectionsList
struct SubsequentCollectionsList: View {
    var collections: [BinCollection]
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("weatherInfoEnabled") var weatherInfoEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subsequent collections")
                .font(sizeClass == .regular ? .title : .title2)
                .bold()
                .padding(.horizontal, sizeClass == .regular ? 40 : 20)
                .padding(.top, sizeClass == .regular ? 60 : 50)
            
            ForEach(collections) { collection in
                VStack {
                    HStack {
                        // Left: Date info and bin labels
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate(collection.date))
                                .font(sizeClass == .regular ? .title3 : .caption)
                            Text(dayAndMonth(for: collection.date))
                                .font(sizeClass == .regular ? .title2 : .headline)
                            
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
                                    .frame(width: sizeClass == .regular ? 90 : 60)
                            }
                        }
                    }
                    .padding(.vertical, sizeClass == .regular ? 40 : 30)
                    .padding(.horizontal, sizeClass == .regular ? 40 : 20)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }

            Link("Report missed bin collection.",
                 destination: URL(string: "https://www.renfrewshire.gov.uk/article/4143/Missed-bin-collection")!)
                .padding(.horizontal)
                .font(.caption)
                .bold()
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

