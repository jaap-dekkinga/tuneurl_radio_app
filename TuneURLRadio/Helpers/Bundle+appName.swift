//
//  Bundle+appName.swift
//  TuneURL
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import Foundation

extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        object(forInfoDictionaryKey: "CFBundleName") as? String ??
        ""
    }
}
