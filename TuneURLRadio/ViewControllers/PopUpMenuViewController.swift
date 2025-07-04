//
//  PopUpMenuViewController.swift
//  TuneURL Radio
//
//  Created by TuneURL.
//  Copyright © 2025 TuneURL. All rights reserved.
//

import UIKit

protocol PopUpMenuViewControllerDelegate: AnyObject {
    func didTapWebsiteButton(_ popUpMenuViewController: PopUpMenuViewController)
    func didTapAboutButton(_ popUpMenuViewController: PopUpMenuViewController)
}

class PopUpMenuViewController: UIViewController {
    
    weak var delegate: PopUpMenuViewControllerDelegate?

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var backgroundView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
    }
    
    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Round corners
        popupView.layer.cornerRadius = 10
        
        // Set background color to clear
        view.backgroundColor = UIColor.clear
        
        // Add gesture recognizer to dismiss view when touched
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeButtonPressed))
        backgroundView.isUserInteractionEnabled = true
        backgroundView.addGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: - IBActions

    @IBAction func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
   
    @IBAction func websiteButtonPressed(_ sender: UIButton) {
        delegate?.didTapWebsiteButton(self)
    }
    
    @IBAction func aboutButtonPressed(_ sender: Any) {
        delegate?.didTapAboutButton(self)
    }
}
