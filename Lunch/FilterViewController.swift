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
    
    var radius : Int = 20
    var rating : Double?
    var price : Double = 25.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let shadowPath = UIBezierPath(rect: enclosingView.bounds)
        enclosingView.layer.masksToBounds = false;
        enclosingView.layer.shadowColor = UIColor.black.cgColor;
        enclosingView.layer.shadowOffset = CGSize(width: 2.0, height: -2.0)
        enclosingView.layer.shadowOpacity = 0.5
        enclosingView.layer.shadowPath = shadowPath.cgPath;
    }
    
    @IBAction func radiusSlider(_ sender: UISlider) {
        radiusLabel.text = "\(Int(sender.value))mi"
        radius = Int(sender.value)
        let name = Notification(name: Notification.Name(rawValue: "updateRadius"))
        NotificationCenter.default.post(name: name.name, object: sender)
    }
    

    @IBAction func ratingSlider(_ sender: UISlider) {
        
        var rating = ""

        switch sender.value {
            
            case 0.0..<1.0:
                rating = "★"
                break
            case 1.0..<2.0:
                rating = "★★"
                break
            case 2.0..<3.0:
                rating = "★★★"
                break
            case 3.0..<4.0:
                rating = "★★★★"
                break
            case 4.0...5.0:
                rating = "★★★★★"
                break
            default:
                break
        }
        
        if ratingLabel.titleLabel?.text != rating {
            ratingLabel.setTitle(rating, for: .normal)
            self.rating = Double(sender.value)
        }
    }
    
    
    @IBAction func priceSlider(_ sender: UISlider) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        priceLabel.titleLabel?.text = formatter.string(from: NSNumber(value: sender.value))
        price = Double(sender.value)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
 

}
