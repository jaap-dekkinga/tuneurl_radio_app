//
//  UIImageView+Cache.swift
//  TuneURL
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import UIKit


extension UIImageView {
    
    func load(url: URL, placeholder: UIImage? = nil, _ completion: (() -> Void)? = nil) {
        let cache = URLCache.shared
        let request = URLRequest(url: url)
        
        if let data = cache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.image = image
                completion?()
            }
        } else {
            self.image = placeholder
            
            URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                guard let data = data, let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode, let image = UIImage(data: data) else { return }
                
                let cachedData = CachedURLResponse(response: httpResponse, data: data)
                cache.storeCachedResponse(cachedData, for: request)
                DispatchQueue.main.async {
                    self?.image = image
                    completion?()
                }
            }.resume()
        }
    }
}
