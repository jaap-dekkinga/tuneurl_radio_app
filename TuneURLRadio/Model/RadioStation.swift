//
//  RadioStation.swift
//  TuneURL Radio
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import UIKit

// Radio Station

struct RadioStation: Codable {
    
    var name: String
    var streamURL: String
    var imageURL: String
    var desc: String
    var longDesc: String
    
    init(name: String, streamURL: String, imageURL: String, desc: String, longDesc: String = "") {
        self.name = name
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.desc = desc
        self.longDesc = longDesc
    }
}

extension RadioStation {
    var shoutout: String {
        "I'm listening to \(name) via \(Bundle.main.appName) app"
    }
}

extension RadioStation: Equatable {
    
    static func == (lhs: RadioStation, rhs: RadioStation) -> Bool {
        return (lhs.name == rhs.name) && (lhs.streamURL == rhs.streamURL) && (lhs.imageURL == rhs.imageURL) && (lhs.desc == rhs.desc) && (lhs.longDesc == rhs.longDesc)
    }
}

extension RadioStation {
    func getImage(completion: @escaping (_ image: UIImage) -> Void) {
        
        if imageURL.range(of: "http") != nil, let url = URL(string: imageURL) {
            // load current station image from network
            UIImage.image(from: url) { image in
                completion(image ?? #imageLiteral(resourceName: "stationImage"))
            }
        } else {
            // load local station image
            let image = UIImage(named: imageURL) ?? #imageLiteral(resourceName: "stationImage")
            completion(image)
        }
    }
}

extension RadioStation {
    
    var trackName: String {
        RadioManager.shared.currentMetadata?.trackName ?? name
    }
    
    var artistName: String {
        RadioManager.shared.currentMetadata?.artistName ?? desc
    }
}
