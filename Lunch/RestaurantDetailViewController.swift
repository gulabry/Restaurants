//
//  RestaurantDetailViewController.swift
//  Lunch
//
//  Created by Bryan Gula on 7/12/17.
//  Copyright © 2017 Gula, Inc. All rights reserved.
//

import UIKit
import GooglePlaces

class RestaurantDetailHolderViewController : UIViewController {
    
    var restaurant : Restaurant?
    var place : GMSPlace?
    
    @IBOutlet weak var container: UIView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embed" {
            let restaurantDetailVC = segue.destination as! RestaurantDetailViewController
            
            if let _ = restaurant {
                restaurantDetailVC.restaurant = restaurant
            } else {
                restaurantDetailVC.place = place
            }
        }
    }
}

class RestaurantDetailViewController: UIViewController {
    
    var restaurant : Restaurant?
    var place : GMSPlace?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var starsLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = restaurant {
            startInfoLoadingWithRestaurant(restaurant: restaurant!)
        } else if let _ = place {
            startInfoLoadingWithPlace(place: place!)
        }
    }
    
    func startInfoLoadingWithRestaurant(restaurant: Restaurant) {
        activityIndicatorView.startAnimating()
        loadFirstPhotoForPlace(placeID: restaurant.placeId)
        
        GMSPlacesClient.shared().lookUpPlaceID(restaurant.placeId, callback: { (place, error) in
            if let _ = place {
                self.titleLabel.text = place!.name
                self.addressLabel.text = place!.formattedAddress
                self.starsLabel.text = "\(String(describing: place!.rating))"
                self.priceLabel.text = "\(String(describing: place!.priceLevel.rawValue))"
            }
        })
    }
    
    func startInfoLoadingWithPlace(place : GMSPlace) {
        activityIndicatorView.startAnimating()
        loadFirstPhotoForPlace(placeID: place.placeID)
        
        GMSPlacesClient.shared().lookUpPlaceID(place.placeID, callback: { (place, error) in
            if let _ = place {
                self.titleLabel.text = place!.name
                self.addressLabel.text = place!.formattedAddress
                self.starsLabel.text = "\(String(describing: place!.rating))"
                self.priceLabel.text = "\(String(describing: place!.priceLevel.rawValue))"
            }
        })
    }
    
    func loadFirstPhotoForPlace(placeID: String) {
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeID) { (photos, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                if let firstPhoto = photos?.results.first {
                    self.loadImageForMetadata(photoMetadata: firstPhoto)
                }
            }
        }
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, callback: {
            (photo, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                self.mainImageView.image = photo;
            }
            
            self.activityIndicatorView.stopAnimating()
            self.activityIndicatorView.isHidden = true
        })
    }
}
