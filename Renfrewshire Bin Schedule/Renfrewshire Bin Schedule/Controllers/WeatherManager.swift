//
//  WeatherManager.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 21/02/2025.
//

import Foundation
import WeatherKit
import Network // For network status checking

@Observable class WeatherManager {
    private let weatherService = WeatherService()
    var weather: Weather?
    var forecastForDate: DayWeather?
    
    // Define the cache keys
    private let weatherCacheKey = "weatherCache"
    private let timestampCacheKey = "weatherTimestampCache"
    
    // Network monitor to check connectivity
    private let networkMonitor = NWPathMonitor()
    private var isConnected: Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var connected = false
        networkMonitor.pathUpdateHandler = { path in
            connected = (path.status == .satisfied)
            semaphore.signal()
        }
        networkMonitor.start(queue: DispatchQueue.global())
        semaphore.wait()
        networkMonitor.cancel()
        return connected
    }

    // Helper to fetch and store weather data
    func getWeather(lat: Double, long: Double, for date: Date) async {
        // Step 1: Load cached data first (if it exists), regardless of age
        if let cachedWeatherData = loadWeatherData() {
            self.weather = cachedWeatherData.weather
            if let dailyForecastArray = cachedWeatherData.dailyForecast {
                self.forecastForDate = dailyForecastArray.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
            }
            print("Loaded cached weather data")
        } else {
            print("No cached weather data available")
        }

        // Step 2: Check if the user is online and if the cache is outdated
        let lastFetchTime = UserDefaults.standard.value(forKey: timestampCacheKey) as? Date
        let hoursDifference = lastFetchTime != nil ? Calendar.current.dateComponents([.hour], from: lastFetchTime!, to: Date()).hour ?? 0 : Int.max
        
        // Only fetch new data if online and cache is older than 2 hours
        if isConnected && hoursDifference >= 2 {
            print("Fetching fresh weather data")
            do {
                // Get the complete weather object (optional)
                weather = try await weatherService.weather(for: .init(latitude: lat, longitude: long))
                
                // Fetch the daily forecast
                let dailyForecast: Forecast<DayWeather> = try await weatherService.weather(for: .init(latitude: lat, longitude: long), including: .daily)
                
                // Update the forecast for the specified date and cache the new data
                self.forecastForDate = dailyForecast.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
                storeWeather(weather: weather, forecast: dailyForecast)
                print("Successfully fetched and cached new weather data")
            } catch {
                print("Failed to fetch weather data: \(error). Using cached data.")
                // No action needed here; cached data is already loaded
            }
        } else {
            if !isConnected {
                print("User is offline. Keeping cached data.")
            } else if hoursDifference < 2 {
                print("Cache is fresh (less than 2 hours old). Keeping cached data.")
            }
        }
    }
    
    // Cache weather data
    func storeWeather(weather: Weather?, forecast: Forecast<DayWeather>) {
        let dailyForecastArray = Array(forecast)
        let weatherData = WeatherData(weather: weather, dailyForecast: dailyForecastArray)
        
        if let encodedData = try? JSONEncoder().encode(weatherData) {
            UserDefaults.standard.setValue(encodedData, forKey: weatherCacheKey)
            UserDefaults.standard.setValue(Date(), forKey: timestampCacheKey)
        }
    }
    
    // Load weather data from cache
    private func loadWeatherData() -> WeatherData? {
        if let data = UserDefaults.standard.data(forKey: weatherCacheKey),
           let decodedWeatherData = try? JSONDecoder().decode(WeatherData.self, from: data) {
            return decodedWeatherData
        }
        return nil
    }
    
    // Properties for weather info
    var icon: String {
        guard let iconName = forecastForDate?.symbolName else { return "tornado" }
        return iconName
    }
    
    var temperature: String {
        guard let temp = forecastForDate?.highTemperature else { return "--" }
        let convert = temp.converted(to: .celsius).value
        return String(Int(convert)) + "°C"
    }
    
    var windSpeed: String {
        guard let wind = forecastForDate?.wind.speed else { return "--" }
        let windSpeedKmh = wind.converted(to: .kilometersPerHour).value
        return String(Int(windSpeedKmh)) + " km/h"
    }
    
    var windGust: String {
        guard let gust = forecastForDate?.wind.gust else { return "--" }
        let gustSpeedKmh = gust.converted(to: .kilometersPerHour).value
        return String(Int(gustSpeedKmh)) + " km/h"
    }
    
    var rainProbability: String {
        guard let chance = forecastForDate?.precipitationChance else { return "--" }
        let chancePercentage = chance * 100
        return String(Int(chancePercentage)) + "%"
    }
    
    var precipitationType: String {
        guard let condition = forecastForDate?.condition else { return "Rain" }
        switch condition {
        case .drizzle, .rain:
            return "Rain"
        case .snow, .heavySnow:
            return "Snow"
        case .sleet, .freezingRain:
            return "Sleet"
        case .hail:
            return "Hail"
        default:
            return "Rain"
        }
    }
}

// MARK: - Codable Structs for Weather Data
struct WeatherData: Codable {
    var weather: Weather?
    var dailyForecast: [DayWeather]?
}
