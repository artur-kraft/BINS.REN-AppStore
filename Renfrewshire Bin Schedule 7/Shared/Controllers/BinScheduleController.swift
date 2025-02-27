//
//  BinScheduleController.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import Foundation
import SwiftUI
import UserNotifications

// MARK: - BinScheduleController
class BinScheduleController: ObservableObject  {
    @Published var collections: [BinCollection] = []
    let calendar = Calendar.current
    let scheduleYear: Int
    let location: String  // Injected location

    // Computed property that formats the location string.
    var formattedLocation: String {
        // For example, convert "Bridge of Weir" to "bridgeofweir"
        location.lowercased().replacingOccurrences(of: " ", with: "")
    }

    // Build the URL dynamically using the formatted location.
    var scheduleURL: URL {
        URL(string: "https://bins.ren/\(formattedLocation).json")!
    }
    
    // Cache file URL – using the caches directory and a unique filename for the location.
    private var cacheURL: URL {
        let fm = FileManager.default
        let cachesDirectory = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent("bin_collections_cache_\(formattedLocation).json")
    }

    init(scheduleYear: Int, location: String) {
        self.scheduleYear = scheduleYear
        self.location = location
        
        // Attempt to load cached collections first.
        loadCollectionsFromCache()
        
        // Then fetch new data in the background.
        fetchCollections()
    }

    // Fetch collection dates from JSON using the dynamically generated URL.
    func fetchCollections() {
        let task = URLSession.shared.dataTask(with: scheduleURL) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            
            do {
                let json = try JSONDecoder().decode([[String: String]].self, from: data)
                self.parseCollections(json: json)
            } catch {
                print("Failed to decode JSON:", error)
            }
        }
        task.resume()
    }
    
    // Parse the JSON data and create BinCollection instances.
    private func parseCollections(json: [[String: String]]) {
        var events: [Date: [BinType]] = [:]
        
        for entry in json {
            for (binKey, dateString) in entry {
                guard let binType = BinType(rawValue: binKey),
                      let date = self.dateFromString(dateString) else { continue }
                
                if events[date] != nil {
                    events[date]?.append(binType)
                } else {
                    events[date] = [binType]
                }
            }
        }
        
        var collectionsArray = events.map { BinCollection(date: $0.key, bins: $0.value) }
        collectionsArray.sort { $0.date < $1.date }
        
        // Update collections and cache only if the new array is not empty.
        if !collectionsArray.isEmpty {
            DispatchQueue.main.async {
                self.collections = collectionsArray
                self.storeCollectionsToCache()
            }
        }
        
        DispatchQueue.main.async {
            self.collections = collectionsArray
            if !collectionsArray.isEmpty {
                self.scheduleNotificationsForUpcomingCollections()
            }
            self.storeCollectionsToCache()
        }


    }
    
    // Convert string to date.
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/London") // Explicitly set
        return formatter.date(from: dateString)
    }
    
    // Get upcoming collections for a given date range.
    func upcomingCollections(from date: Date = Date(), count: Int = 4) -> [BinCollection] {
        return collections.filter {
            calendar.isDate($0.date, inSameDayAs: date) || $0.date > date
        }
        .prefix(count)
        .map { $0 }
    }
    
    // MARK: - Notifications
    func scheduleNotificationsForUpcomingCollections() {
        // Cancel all existing notifications (optional: or just the ones that are outdated)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Determine which collections you want to schedule notifications for.
        // For example, schedule notifications for collections in the next 60 days.
        let now = Date()
        let futureCollections = collections.filter { collection in
            return collection.date >= now &&
                   collection.date <= Calendar.current.date(byAdding: .day, value: 60, to: now)!
        }
        
        // Schedule notifications for these collections, up to the allowed limit.
        for collection in futureCollections.prefix(64) {
            scheduleNotifications(for: collection, location: location)
        }
    }

    func scheduleNotifications(for collection: BinCollection, location: String) {
        let content = UNMutableNotificationContent()
        content.title = "Bin Collection in \(location)"
        
        let binNames = collection.bins.map { $0.displayName }.joined(separator: ", ")
        content.body = "Tomorrow's collection: \(binNames)"
        content.sound = .default
        
        // Use London time zone for all calculations
        var londonCalendar = Calendar(identifier: .gregorian)
        guard let londonTimeZone = TimeZone(identifier: "Europe/London") else { return }
        londonCalendar.timeZone = londonTimeZone
        
        // Set the collection time 
        guard let scheduledDate = londonCalendar.date(
            bySettingHour: 15,
            minute: 00,
            second: 50,
            of: collection.date
        ) else {
            print("Failed to set time for \(collection.date)")
            return
        }
        
        // Calculate the day before (for notification)
        guard let dayBefore = londonCalendar.date(
            byAdding: .day,
            value: -1,
            to: scheduledDate
        ) else {
            print("Failed to subtract day")
            return
        }
        
        // Debug print (London time)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm z"
        formatter.timeZone = londonTimeZone
        
        print("Current London time: \(formatter.string(from: Date()))")
        print("Notification scheduled for \(formatter.string(from: dayBefore))")
        
        // Check if the trigger is in the future
        if dayBefore <= Date() {
            print("Trigger time is in the past. Adjust your scheduling logic.")
            return
        }
        
        let components = londonCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: dayBefore)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    


    
    // MARK: - Caching
    
    // Save the current collections to cache.
    private func storeCollectionsToCache() {
        do {
            let data = try JSONEncoder().encode(collections)
            try data.write(to: cacheURL)
        } catch {
            print("Error storing collections to cache: \(error)")
        }
    }
    
    // Load collections from cache.
    private func loadCollectionsFromCache() {
        do {
            let data = try Data(contentsOf: cacheURL)
            let cachedCollections = try JSONDecoder().decode([BinCollection].self, from: data)
            DispatchQueue.main.async {
                self.collections = cachedCollections
            }
        } catch {
            print("No cache available or error loading cache: \(error)")
        }
    }
}
