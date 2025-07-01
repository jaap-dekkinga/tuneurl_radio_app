//
//  TuneURL-Settings.swift
//  TuneURL Radio
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import UIKit

struct Config {
    
    static let debugLog = true

    // If this is set to "true", it will use the JSON file in the app
    // Set it to "false" to use the JSON file at the stationDataURL
    static let useLocalStations = true
    static let stationsURL = "https://fethica.com/assets/swift-radio/stations.json"

    // Set this to "true" to enable the search bar
    static let searchable = false

    // Set this to "false" to show the next/previous player buttons
    static let hideNextPreviousButtons = true
    
    // Contact infos
    static let website = "https://github.com/analogcode/Swift-Radio-Pro"
    static let email = "contact@fethica.com"
    static let emailSubject = "From \(Bundle.main.appName) App"
}

