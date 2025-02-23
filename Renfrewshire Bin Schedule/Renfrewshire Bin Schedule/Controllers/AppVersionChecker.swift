//
//  AppVersionChecker.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 19/02/2025.
//


import Foundation

enum VersionError: Error {
    case invalidBundleID
    case invalidBundleInfo
    case invalidResponse
}

class AppVersionChecker {
    static func isNewVersionAvailable(completion: @escaping (Bool, URL?) -> Void) {
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                  let bundleID = Bundle.main.bundleIdentifier else {
                      completion(false, nil)
                      return
                  }
        
        let lookupURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)&country=gb")!
        
        URLSession.shared.dataTask(with: lookupURL) { data, response, error in
    guard let data = data, error == nil else {
    completion(false, nil)
        return
    }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let results = json?["results"] as? [[String: Any]],
                          let appStoreVersion = results.first?["version"] as? String,
                let appStoreURLString = results.first?["trackViewUrl"] as? String,
                let appStoreURL = URL(string: appStoreURLString) else {
    completion(false, nil)
                    return
                }
                
                let currentVersionParts = currentVersion.components(separatedBy: ".").compactMap { Int($0) }
                let appStoreVersionParts = appStoreVersion.components(separatedBy: ".").compactMap { Int($0) }
                
                for (current, appStore) in zip(currentVersionParts, appStoreVersionParts) {
                    if appStore > current {
                        completion(true, appStoreURL)
                        return
                    } else if appStore < current {
                        break
                    }
                }
                
                if appStoreVersionParts.count > currentVersionParts.count {
                    completion(true, appStoreURL)
                } else {
                    completion(false, nil)
                }
                
            } catch {
                completion(false, nil)
            }
        }.resume()
    }
}
