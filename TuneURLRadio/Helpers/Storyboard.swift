//
//  Storyboard.swift
//  TuneURL
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import UIKit

struct Storyboard<T: UIViewController> {
    
    static var storyboardName: String {
        return String(describing: T.self)
    }
    
    static var viewController: T {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let vc = storyboard.instantiateViewController(withIdentifier: Self.storyboardName) as? T else {
            fatalError("Could not get controller from Storyboard: \(Self.storyboardName)")
        }
        
        return vc
    }
}
