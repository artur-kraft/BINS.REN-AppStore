//
//  WeatherManager.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 21/02/2025.
//

import Foundation
import WeatherKit

@Observable class WeatherManager {
    private let weatherService = WeatherService()
    var weather: Weather?
    var forecastForDate: DayWeather?
    
    // Define the cache keys
    private let weatherCacheKey = "weatherCache"
    private let timestampCacheKey = "weatherTimestampCache"
    
    // Helper to fetch and store weather data
    func getWeather(lat: Double, long: Double, for date: Date) async {
        // Check if the cache is still valid (less than 6 hours old)
        if let lastFetchTime = UserDefaults.standard.value(forKey: timestampCacheKey) as? Date {
            let hoursDifference = Calendar.current.dateComponents([.hour], from: lastFetchTime, to: Date()).hour ?? 0
            if hoursDifference < 2 {
                // If data was fetched within the last 2 hours, use the cached data
                if let cachedWeatherData = loadWeatherData() {
                    self.weather = cachedWeatherData.weather
                    if let dailyForecastArray = cachedWeatherData.dailyForecast {
                        self.forecastForDate = dailyForecastArray.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
                    }
                    print("using cached data")
                    return
                }
            }
            print("not using cached data")
        }

        // If the cache is outdated or empty, fetch fresh data
        do {
            // Get the complete weather object (optional, not strictly needed for daily)
            weather = try await weatherService.weather(for: .init(latitude: lat, longitude: long))
            
            // Fetch the daily forecast
            let dailyForecast: Forecast<DayWeather> = try await weatherService.weather(for: .init(latitude: lat, longitude: long), including: .daily)
            
            // Store the new weather and full forecast in cache
            self.forecastForDate = dailyForecast.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
            storeWeather(weather: weather, forecast: dailyForecast)
            
        } catch {
            print("Failed to get weather data. \(error)")
        }
    }

    
    // Cache weather data
    func storeWeather(weather: Weather?, forecast: Forecast<DayWeather>) {
        // Convert the Forecast<DayWeather> to an array
        let dailyForecastArray = Array(forecast)
        
        // Store the weather and the full daily forecast in a struct
        let weatherData = WeatherData(weather: weather, dailyForecast: dailyForecastArray)
        
        // Save the data as encoded JSON and update the cache timestamp
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
    var dailyForecast: [DayWeather]?  // Store all daily forecasts (e.g., for 14 days)
}
