//
//  Places.swift
//  Lunch
//
//  Created by Bryan Gula on 7/12/17.
//  Copyright © 2017 Gula, Inc. All rights reserved.
//

import Foundation
import GooglePlaces

struct Restaurant {
    
    var id : String
    var placeId : String
    var name : String
    var lat : Double
    var long : Double
    var icon : URL
    var rating : Double?
    var distanceFromSelectedPlaceInMiles : Double?
    var vicinity : String?
    
    static func searchNearby(options: [String:Any], success: @escaping ([Restaurant]) -> Void, failure: @escaping (Error, String) -> Void) {
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(options["latitude"]!),\(options["longitude"]!)&radius=\(options["radius"]!)&type=restaurant&key=\(Constants.placesSdkKey)")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                
                let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:Any]
                
                var restaurants = [Restaurant]()
                
                let results = json["results"] as! [[String:Any?]]
                
                for place in results {
                    
                    //  Location
                    //
                    var locationLat = 0.0
                    var locationLong = 0.0
                    
                    if let geo = place["geometry"] as? [String:Any] {
                        if let location = geo["location"] as? [String:Double] {
                            locationLat = location["lat"]!
                            locationLong = location["lng"]!
                        }
                    }
                    
                    //  Icon, Place, Name, Place ID, Rating, Vicinity
                    //
                    var icon = ""
                    
                    if let placeIcon = place["icon"] as? String {
                        icon = placeIcon
                    }
                    let id = place["id"] as! String
                    let name = place["name"] as! String
                    let placeId = place["place_id"] as! String
                    
                    var rating = 0.0
                    if let placeRating = place["rating"] as? Double {
                        rating = placeRating
                    }
                    let vicinity = place["vicinity"] as! String
                    
                    let restaurant = Restaurant(id: id, placeId: placeId, name: name, lat: locationLat, long: locationLong, icon: URL(string: icon)!, rating: rating, distanceFromSelectedPlaceInMiles: 0.0, vicinity: vicinity)
                    restaurants.append(restaurant)
                }
                
                success(restaurants)
                
            } else {
                failure(error!, "parsing places api response json failed")
            }
        })
        
        task.resume()
        URLSession.shared.finishTasksAndInvalidate()
    }
}
