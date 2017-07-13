//
//  FilterViewController.swift
//  Lunch
//
//  Created by Bryan Gula on 7/10/17.
//  Copyright © 2017 Gula, Inc. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController {

    @IBOutlet var enclosingView: UIView!
    @IBOutlet var radiusLabel: UILabel!
    @IBOutlet var ratingLabel: UIButton!
    @IBOutlet var priceLabel: UIButton!
    
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var ratingSlider: UISlider!
    @IBOutlet weak var priceSlider: UISlider!
    
    var radius : Int?
    var rating : Double?
    var price : Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSliders()
        
        let shadowPath = UIBezierPath(rect: enclosingView.bounds)
        enclosingView.layer.masksToBounds = false;
        enclosingView.layer.shadowColor = UIColor.black.cgColor;
        enclosingView.layer.shadowOffset = CGSize(width: 2.0, height: -2.0)
        enclosingView.layer.shadowOpacity = 0.5
        enclosingView.layer.shadowPath = shadowPath.cgPath;
    }
    
    func setupSliders() {
        radius = UserDefaults.standard.integer(forKey: "radius")
        rating = UserDefaults.standard.double(forKey: "rating")
        price = UserDefaults.standard.double(forKey: "price")
        
        radiusLabel.text = "\(radius!)mi"
        radiusSlider.setValue(Float(radius!), animated: true)
        radiusSlider.isContinuous = false
        
        ratingLabel.setTitle(getStarsForRating(rating: rating!), for: .normal)
        ratingSlider.setValue(Float(rating!), animated: true)
        ratingSlider.isContinuous = false
        
        priceLabel.setTitle(getQuoteForPrice(price: Int(price!)), for: .normal)
        priceSlider.setValue(Float(price!), animated: true)
        priceSlider.isContinuous = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //  Write settings to defaults so they can be loaded later
        //
        UserDefaults.standard.set(radius, forKey: "radius")
        UserDefaults.standard.set(rating, forKey: "rating")
        UserDefaults.standard.set(price, forKey: "price")
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func radiusSlider(_ sender: UISlider) {
        radiusLabel.text = "\(Int(sender.value))mi"
        radius = Int(sender.value)
        let name = Notification(name: Notification.Name(rawValue: "updateRadius"))
        NotificationCenter.default.post(name: name.name, object: sender)
    }
    
    @IBAction func ratingSlider(_ sender: UISlider) {
        
        var rating = getStarsForRating(rating: Double(sender.value))
        
        if ratingLabel.titleLabel?.text != rating {
            ratingLabel.setTitle(rating, for: .normal)
            self.rating = Double(sender.value)
            let rating = Notification(name: Notification.Name(rawValue: "updateRating"))
            NotificationCenter.default.post(name: rating.name, object: sender)
        }
    }
    
    
    @IBAction func priceSlider(_ sender: UISlider) {

        let price = getQuoteForPrice(price: Int(sender.value))

        priceLabel.setTitle(price, for: .normal)
        let priceValue = Notification(name: Notification.Name(rawValue: "updatePrice"))
        NotificationCenter.default.post(name: priceValue.name, object: sender)
    }
    
    //  MARK: Helper Functions
 
    func getStarsForRating(rating : Double) -> String {
        switch rating {
        case 0.0..<1.0:
            return "★"
        case 1.0..<2.0:
            return "★★"
        case 2.0..<3.0:
            return "★★★"
        case 3.0..<4.0:
            return "★★★★"
        case 4.0...5.0:
            return "★★★★★"
        default:
            return ""
        }
    }
    
    func getQuoteForPrice(price : Int) -> String {
        switch Double(price) {
        case 1:
            return "Free"
        case 2:
            return "Inexpensive"
        case 3:
            return "Moderate"
        case 4:
            return "Expensive"
        case 5:
            return "Very Expensive"
        default:
            return ""
        }
    }
}
