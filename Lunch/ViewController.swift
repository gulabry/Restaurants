//
//  ViewController.swift
//  Lunch
//
//  Created by Bryan Gula on 7/7/17.
//  Copyright © 2017 Gula, Inc. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, GMSMapViewDelegate {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    
    var likelyPlaces: [GMSAutocompletePrediction] = []
    var resultMarkers: [GMSMarker] = []
    var selectedPlace: GMSPlace?
    var nearbyRestaurants = [Restaurant]()
    var filteredRestaurants = [Restaurant]()
    
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    let keyboard = Typist.shared
    var searchTextField : SearchTextField? = nil
    var filterButton : UIButton?
    var dismissTapView : UIView?
    var showListView = false
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var showRestaurantListButton: UIButton!
    @IBOutlet weak var randomRestaurantButton: UIButton!
    
    var mapScaleFactor : Double = 14.0 {
        didSet {
            mapView.animate(toZoom: Float(mapScaleFactor))
        }
    }
    
    var desiredRadius : Int = 10 {
        didSet {
            mapScaleFactor = 15.0 + (Double(desiredRadius) * -0.10)
        }
    }
    
    var desiredRating : Double = 3.0 {
        didSet {
            
        }
    }
    
    var desiredPrice : Int = 2 {
        didSet {
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        setupLocationServices()
        setupView()
        setupNotifications()
        configureKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
    }
    
    func setupView() {
        self.tableView.isHidden = true
        self.showRestaurantListButton.isHidden = true
        self.randomRestaurantButton.isHidden = true
    }
    
    func filterRestaruantsByOptions() {
        for restaurant in nearbyRestaurants {
            let price = restaurant
        }
    }
    
    func setupMap() {
        
    }
    
    func setupNotifications() {
        let updateRadius = Notification(name: Notification.Name(rawValue: "updateRadius"))
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.changeRadius(notification:)), name: updateRadius.name, object: nil)
        
        let updateRating = Notification(name: Notification.Name(rawValue: "updateRating"))
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.changeRadius(notification:)), name: updateRating.name, object: nil)
        
        let updatePrice = Notification(name: Notification.Name(rawValue: "updatePrice"))
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.changeRadius(notification:)), name: updatePrice.name, object: nil)
    }
    
    func changeRadius(notification : Notification) {
        desiredRadius = Int((notification.object as! UISlider).value)
    }
    
    func changeRating(notification : Notification) {
        desiredRating = Double((notification.object as! UISlider).value)
    }
    
    func changePrice(notification : Notification) {
        desiredPrice = Int((notification.object as! UISlider).value)
    }
    
    func setupSearch() {
        
        filterButton = UIButton(type: .system)
        filterButton?.frame = CGRect(x: view.frame.width - 58, y: 26, width: 38, height: 48)
        filterButton?.setImage(UIImage(named: "filter"), for: .normal)
        filterButton?.tintColor = .black
        filterButton?.addTarget(self, action: #selector(ViewController.showFilter), for: .touchUpInside)
        
        searchTextField = SearchTextField(frame: CGRect(x: 10, y: 20, width: view.frame.width - 20, height: 60))
        searchTextField?.borderStyle = .none
        searchTextField?.backgroundColor = .white
        searchTextField?.layer.masksToBounds = false
        searchTextField?.layer.shadowRadius = 1.0
        searchTextField?.layer.shadowColor = UIColor.black.cgColor
        searchTextField?.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        searchTextField?.layer.shadowOpacity = 0.5
        searchTextField?.layer.cornerRadius = 4.0
        searchTextField?.delegate = self
        searchTextField?.returnKeyType = UIReturnKeyType.done
        searchTextField?.keyboardAppearance = .dark
        
        let attributes = [
            NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.5),
            NSFontAttributeName : UIFont(name: "AppleSDGothicNeo-UltraLight", size: 24)!
        ]
        
        searchTextField?.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 24)!
        searchTextField?.attributedPlaceholder = NSAttributedString(string: "Search", attributes:attributes)
        
        view.insertSubview(searchTextField!, aboveSubview: view)
        view.insertSubview(filterButton!, aboveSubview: searchTextField!)
    }
    
    func setupLocationServices() {
        
        let status = CLLocationManager.authorizationStatus()
        locationManager.delegate = self
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            
        } else if status == .restricted || status == .denied {
            print("app cannot use location services")
            
        } else if status == .authorizedWhenInUse {
            
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 50
            locationManager.startUpdatingLocation()
            
            placesClient = GMSPlacesClient.shared()
            
            // Create a map.
            let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                                  longitude: defaultLocation.coordinate.longitude,
                                                  zoom: Float(mapScaleFactor))
            mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
            mapView.settings.myLocationButton = false
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mapView.isMyLocationEnabled = true
            mapView.setMinZoom(10, maxZoom: 20)
            mapView.delegate = self
            
            do {
                // Set the map style by passing the URL of the local file.
                if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } else {
                    NSLog("Unable to find style.json")
                }
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
            
            view.insertSubview(mapView, at: 0)
            mapView.isHidden = true
        }
    }
    
    //  MARK:   UITextField Delegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        DispatchQueue.main.async {
            
            let attributes = [
                NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.5),
                NSFontAttributeName : UIFont(name: "AppleSDGothicNeo-UltraLight", size: 24)!
            ]
            
            UIView.animate(withDuration: 0.25, animations: {
                self.searchTextField?.textColor = .white
                self.searchTextField?.attributedPlaceholder = NSAttributedString(string: "Search", attributes:attributes)
                self.filterButton?.tintColor = .white
                self.searchTextField?.backgroundColor = UIColor.darkGray
            })
        }
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                //self.searchTextField?.transform = CGAffineTransform.identity
                self.searchTextField?.textColor = .black
                self.searchTextField?.backgroundColor = .white
                self.filterButton?.tintColor = .black
            })
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        placeAutocomplete(query: textField.text! + string)
        return true
    }
    
    func updateSearchResultsView() {
        DispatchQueue.main.async {
            if self.likelyPlaces.count == 0 || self.searchTextField?.text!.characters.count == 0 {
                self.tableView.isHidden = true
            } else {
                self.tableView.isHidden = false
                self.tableView.reloadData()
            }
            
            self.showRestaurantListButton.isHidden = true
            self.randomRestaurantButton.isHidden = true
        }
    }
    
    func showNearbyRestaurantsOnMap(restaurants : [Restaurant]) {
        
        let boundsRegion = GMSCoordinateBounds()
        
        for restaurant in restaurants {
            let position = CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.long)
            let marker = GMSMarker(position: position)
            marker.title = restaurant.name
            marker.appearAnimation = .pop
            marker.isFlat = true
            marker.map = self.mapView
            
            boundsRegion.includingCoordinate(marker.position)
            resultMarkers.append(marker)
        }
        
        //  Add selected address to map
        //
        let position = CLLocationCoordinate2D(latitude: (self.selectedPlace?.coordinate.latitude)!, longitude: (self.selectedPlace?.coordinate.longitude)!)
        let marker = GMSMarker(position: position)
        marker.icon = GMSMarker.markerImage(with: .blue)
        marker.title = self.selectedPlace?.name
        marker.appearAnimation = .pop
        marker.map = self.mapView
        resultMarkers.append(marker)
        
        DispatchQueue.main.async {
            self.mapView.selectedMarker = marker
            //self.mapView.animate(toLocation: (self.selectedPlace?.coordinate)!)
            //self.mapView.animate(toZoom: Float(self.mapScaleFactor))
            self.mapView.animate(with: GMSCameraUpdate.fit(boundsRegion, withPadding: 10))
            
            UIView.animate(withDuration: 0.25, animations: { 
                self.showRestaurantListButton.isHidden = false
                self.randomRestaurantButton.isHidden = false
            })
        }
    }
    
    func showFilter() {
        performSegue(withIdentifier: "showResturants", sender: nil)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        searchTextField?.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField?.resignFirstResponder()
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        var tappedPlace : Restaurant?
        
        for place in nearbyRestaurants {
            if marker.position.latitude == place.lat && marker.position.longitude == place.long  {
                tappedPlace = place
            }
        }
        
        if let place = tappedPlace {
            performSegue(withIdentifier: "showRestaurantDetail", sender: place)
        }
        
        return true
    }
    
    func prepRestaurantListView() {
        DispatchQueue.main.async {
            let newFrame = self.tableView.frame
            let newY = newFrame.origin.y + 46
            let newHeight = self.view.frame.height - newY - 10
            
            self.tableView.frame = CGRect(x: newFrame.origin.x, y: newY, width: newFrame.width, height: newHeight)
        }
    }
    
    @IBAction func showRestaurantList(_ sender: Any) {
        
        if showListView {
            showListView = false
            self.tableView.rowHeight = 40

        } else {
            showListView = true
            prepRestaurantListView()
            self.tableView.rowHeight = 85
            
            DispatchQueue.main.async {
                self.tableView.isHidden = false
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func pickRandomRestaurant(_ sender: Any) {
        let randomRestaurant = nearbyRestaurants[Int(arc4random_uniform(UInt32(nearbyRestaurants.count)))]
        placesClient.lookUpPlaceID(randomRestaurant.placeId) { (place, err) in
            self.mapView.clear()
            self.selectedPlace = place
            self.searchTextField?.resignFirstResponder()
            self.mapView.animate(toLocation: place!.coordinate)
            //  Add selected address to map
            //
            let position = CLLocationCoordinate2D(latitude: (self.selectedPlace?.coordinate.latitude)!, longitude: (self.selectedPlace?.coordinate.longitude)!)
            let marker = GMSMarker(position: position)
            marker.icon = GMSMarker.markerImage(with: .blue)
            marker.title = self.selectedPlace?.name
            marker.appearAnimation = .pop
            marker.map = self.mapView
            
            self.mapView.selectedMarker = marker
            print("random selected place: \(place!.formattedAddress!)")
        }
    }

    @IBAction func dismissKeyboard(_ sender: Any) {
        searchTextField?.resignFirstResponder()
    }
    
    //  MARK:   Search View Add/Dismiss Methods
    
    func addDismissView() {
        dismissTapView = UIView(frame: view.bounds)
        dismissTapView?.backgroundColor = .clear
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard(_:)))
        
        dismissTapView?.addGestureRecognizer(dismissKeyboardTap)
        
        view.insertSubview(dismissTapView!, belowSubview: self.searchTextField!)
    }
    
    func removeDismissView() {
        dismissTapView?.removeFromSuperview()
    }
    
    //  MARK:   UITableView Data Source & Delegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if showListView {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as! RestaurantCell
            
            let restaurant = nearbyRestaurants[indexPath.row]
            
            cell.titleLabel.text = restaurant.name
            
            let distanceInMeters = GMSGeometryDistance((selectedPlace!.coordinate), CLLocationCoordinate2DMake(restaurant.lat, restaurant.long))
            
            let milesDistance = distanceInMeters / 1609.34  //  devide by a mile in meters
            
            restaurant.distanceFromSelectedPlaceInMiles = milesDistance
            
            cell.distanceLabel.text = "\(round(milesDistance * 100) / 100)mi"
            
            placesClient.lookUpPlaceID(restaurant.placeId, callback: { (place, error) in
                DispatchQueue.main.async {
                    cell.addressLabel.text = place!.formattedAddress
                }
            })
            
            placesClient.lookUpPhotos(forPlaceID: restaurant.placeId, callback: { (list, error) in
                let first = list?.results.first
                self.placesClient.loadPlacePhoto(first!, callback: { (image, error) in
                    DispatchQueue.main.async {
                        cell.iconImageView.image = image
                    }
                })
            })
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath)
            
            let place = likelyPlaces[indexPath.row]
            
            let regularFont = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 20)!
            let boldFont = UIFont(name: "AppleSDGothicNeo-Medium", size: 20)!
            
            let bolded = place.attributedFullText.mutableCopy() as! NSMutableAttributedString
            bolded.enumerateAttribute(kGMSAutocompleteMatchAttribute, in: NSMakeRange(0, bolded.length), options: []) {
                (value, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let font = (value == nil) ? regularFont : boldFont
                bolded.addAttribute(NSFontAttributeName, value: font, range: range)
            }
            
            cell.textLabel?.attributedText = bolded
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let predictedPlace = likelyPlaces[indexPath.row]
        searchTextField?.attributedText = predictedPlace.attributedPrimaryText
        tableView.isHidden = true
        
        placesClient.lookUpPlaceID(predictedPlace.placeID!) { (place, err) in
            self.mapView.clear()
            self.selectedPlace = place
            self.searchTextField?.resignFirstResponder()
            self.mapView.animate(toLocation: place!.coordinate)
            
            let options = [
                "latitude": place!.coordinate.latitude,
                "longitude": place!.coordinate.longitude,
                "radius": Int(1609 * self.desiredRadius) // Miles to METERS
            ] as [String : Any]
            
            Restaurant.searchNearby(options: options, success: { (restaurants) in
                
                self.nearbyRestaurants = restaurants
                self.showNearbyRestaurantsOnMap(restaurants: restaurants)
                
            }, failure: { (error, reason) in
                print(error, reason)
            })
            
            print("user selected place: \(place!.formattedAddress!)")
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showListView {
            return nearbyRestaurants.count
        } else {
            return likelyPlaces.count
        }
    }
    
    //  MARK:   Typest Keyboard Observer
    
    func configureKeyboard() {
        keyboard
            .on(event: .willChangeFrame) { (options) in
                
                
                print("New Keyboard Frame is \(options.endFrame).")
            }
            .on(event: .willHide) { (options) in
                

                print("It took \(options.animationDuration) seconds to animate keyboard out.")
            }
            .start()
    }
    
    func mapViewSnapshotReady(_ mapView: GMSMapView) {
        mapView.delegate = self
    }
    
    //  MARK: GMSAutocompleteTableDataSource Methods
    
    func placeAutocomplete(query : String) {
        let filter = GMSAutocompleteFilter()
        filter.type = .noFilter
        
        placesClient.autocompleteQuery(query, bounds: nil, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                print("Autocomplete error \(error)")
                return
            }
            if let results = results {
                self.likelyPlaces = results
                
                DispatchQueue.main.async {
                    
                    self.updateSearchResultsView()

                    let newHeight = Int(self.tableView.rowHeight) * self.likelyPlaces.count
                    
                    let newFrame = CGRect(x: self.tableView.frame.origin.x, y: self.tableView.frame.origin.y, width: self.tableView.frame.width, height: CGFloat(newHeight))
                    
                    UIView.animate(withDuration: 0.0, animations: {
                        self.tableView.frame = newFrame
                    })
                }
                
                for result in results {
                    print("Result \(result.attributedFullText) with placeID \(String(describing: result.placeID))")
                }
            }
        })
    }
    
    //  MARK: Segue Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRestaurantDetail" {
            let destinitation = segue.destination as! RestaurantDetailHolderViewController
            destinitation.restaurant = sender as? Restaurant
        }
    }
    
    @IBAction func dismissToMap(segue : UIStoryboardSegue) {
        print("back to map")
    }
}

// Delegates to handle events for the location manager.
extension ViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        self.currentLocation = location
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: Float(mapScaleFactor))
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK")
            setupLocationServices()
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

class RestaurantCell : UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
}

class SearchTextField : UITextField {
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        super.editingRect(forBounds: bounds)
        return CGRect(x: 10, y: 0, width: bounds.width, height: bounds.height)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        super.textRect(forBounds: bounds)
        return CGRect(x: 10, y: 0, width: bounds.width, height: bounds.height)
    }
}

