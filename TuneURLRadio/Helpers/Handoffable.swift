//
//  Handoffable.swift
//  TuneURL
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import UIKit

protocol Handoffable: UIResponder {}

extension Handoffable {
    
    func setupHandoffUserActivity() {
        userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity?.becomeCurrent()
    }
    
    func updateHandoffUserActivity(_ activity: NSUserActivity?, station: RadioStation?) {
        guard let activity = activity else { return }
        
        defer { updateUserActivityState(activity) }
        
        guard let metadata = RadioManager.shared.currentMetadata, let artistName = metadata.artistName, let trackName = metadata.trackName else {
            activity.webpageURL = nil
            return
        }
        
        activity.webpageURL = getHandoffURL(artistName: artistName, trackName: trackName)
    }
    
    private func getHandoffURL(artistName: String, trackName: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "google.com"
        components.path = "/search"
        components.queryItems = [URLQueryItem]()
        components.queryItems?.append(URLQueryItem(name: "q", value: "\(artistName) \(trackName)"))
        return components.url
    }
}
