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
    @IBOutlet weak var sortAndClearButton: UIButton!
    @IBOutlet weak var showVisualsForDataButton: UIButton!
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    var tableViewHeightDefault : CGFloat?
    
    @IBOutlet weak var tableViewTopLayout: NSLayoutConstraint!
    var tableViewTopLayoutDefault : CGFloat?
    
    var mapScaleFactor : Double = 13.5 {
        didSet {
            //mapView.animate(toZoom: Float(mapScaleFactor))
        }
    }
    
    var desiredRadius : Int = 15 {
        didSet {
            //mapScaleFactor = 15.0 + (Double(desiredRadius) * -0.10)
            filterRestaruantsByOptions()
        }
    }
    
    var desiredRating : Double = 3.0 {
        didSet {
            filterRestaruantsByOptions()
        }
    }
    
    var desiredPrice : Int = 2 {
        didSet {
            filterRestaruantsByOptions()
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
        
        tableViewHeightDefault = tableViewHeight.constant
        tableViewTopLayoutDefault = tableViewTopLayout.constant
        
        self.tableView.isHidden = true
        self.showRestaurantListButton.isHidden = true
        self.randomRestaurantButton.isHidden = true
    }
    
    func filterRestaruantsByOptions() {
        filteredRestaurants.removeAll()
        mapView.clear()
        for restaurant in nearbyRestaurants {
            if let price = restaurant.priceLevel {
                if let rating = restaurant.rating {
                    if let radius = restaurant.distanceFromSelectedPlaceInMiles {
                        if price <= desiredPrice && rating >= desiredRating && radius <= Double(desiredRadius) {
                            filteredRestaurants.append(restaurant)
                        }
                    }
                }
            }
        }
        if filteredRestaurants.count > 0 {
            showNearbyRestaurantsOnMap(restaurants: filteredRestaurants)
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
                                                  zoom: 13.5)
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
            
            UIView.animate(withDuration: 0.15, animations: {
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
            
            let attributes = [
                NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.5),
                NSFontAttributeName : UIFont(name: "AppleSDGothicNeo-UltraLight", size: 24)!
            ]
            
            UIView.animate(withDuration: 0.15, animations: {
                self.searchTextField?.attributedPlaceholder = NSAttributedString(string: "Search", attributes:attributes)
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
        
        DispatchQueue.main.async {
            
            //  Add selected address to map
            //
            let position = CLLocationCoordinate2D(latitude: (self.selectedPlace?.coordinate.latitude)!, longitude: (self.selectedPlace?.coordinate.longitude)!)
            let marker = GMSMarker(position: position)
            marker.icon = GMSMarker.markerImage(with: .blue)
            marker.title = self.selectedPlace?.name
            marker.appearAnimation = .pop
            marker.map = self.mapView
            self.resultMarkers.append(marker)
            
            self.mapView.selectedMarker = marker
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

        if selectedPlace!.coordinate.latitude == marker.position.latitude && selectedPlace!.coordinate.longitude == marker.position.longitude  {
            performSegue(withIdentifier: "showRestaurantDetail", sender: selectedPlace!)
            return true
        }
        
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
            
            self.tableView.isHidden = false

            let buttonOffset = self.showRestaurantListButton.frame.maxY - 10
            let newHeight = self.view.frame.height - buttonOffset + 20
            
            self.tableView.rowHeight = 85
            self.tableViewTopLayout.constant = buttonOffset
            self.tableViewHeight.constant = newHeight - 20
            self.tableView.reloadData()
        }
    }
    
    func resetRestaurantListView() {
        DispatchQueue.main.async {
            
            self.tableView.rowHeight = 40
            
            self.tableViewTopLayout.constant = self.tableViewTopLayoutDefault!
            self.tableViewHeight.constant = self.tableViewHeightDefault!
            
            self.tableView.isHidden = true
        }
    }
    
    @IBAction func clearAndSortTrigger(_ sender: Any) {
        if showListView {

        } else {

        }
    }
    
    @IBAction func showVisualRankingData(_ sender: Any) {
        
        
    }
    
    @IBAction func showRestaurantList(_ sender: Any) {
        
        if showListView {
            
            DispatchQueue.main.async {
                self.showListView = false
                self.resetRestaurantListView()
                self.showNearbyRestaurantsOnMap(restaurants: self.nearbyRestaurants)
                self.showRestaurantListButton.setTitle("Show List", for: .normal)
                self.sortAndClearButton.backgroundColor = #colorLiteral(red: 0.3398334384, green: 0.6123188138, blue: 0.7547396421, alpha: 1)
                self.sortAndClearButton.titleLabel?.textColor = .white
                if self.sortAndClearButton.titleLabel?.text == "Clear" {
                    self.sortAndClearButton.setTitle("Sort Rating", for: .normal)

                } else if self.sortAndClearButton.titleLabel?.text == "Sort Rating" {
                    self.sortAndClearButton.setTitle("Sort Price", for: .normal)

                }
            }
            
        } else {
            
            self.showListView = true
            self.mapView.clear()
            self.prepRestaurantListView()
            self.showRestaurantListButton.setTitle("Hide List", for: .normal)
            sortAndClearButton.backgroundColor = .white
            sortAndClearButton.titleLabel?.textColor = .black
            searchTextField?.text = ""
        
        }
    }
    
    func calculateDistancesForRestaurants() {
        
        if let _ = selectedPlace {
            for (index, _) in nearbyRestaurants.enumerated() {
                
                let distanceInMeters = GMSGeometryDistance((selectedPlace?.coordinate)!, CLLocationCoordinate2DMake(nearbyRestaurants[index].lat, nearbyRestaurants[index].long))
                
                let milesDistance = distanceInMeters / 1609.34  //  devide by a mile in meters
                
                nearbyRestaurants[index].distanceFromSelectedPlaceInMiles = round(milesDistance * 100) / 100
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
            
            if let miles = restaurant.distanceFromSelectedPlaceInMiles {
                cell.distanceLabel.text = "\(miles)mi"
            }
            
            placesClient.lookUpPlaceID(restaurant.placeId, callback: { (place, error) in
                DispatchQueue.main.async {
                    if let _ = place {
                        cell.addressLabel.text = place!.formattedAddress
                    }
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
        
        if showListView  {
            let restaruant = nearbyRestaurants[indexPath.row]
            tableView.isHidden = true
            
            placesClient.lookUpPlaceID(restaruant.placeId) { (place, err) in
                self.mapView.clear()
                self.selectedPlace = place
                self.searchTextField?.resignFirstResponder()
                self.mapView.animate(toLocation: place!.coordinate)
                
                let options = [
                    "latitude": place!.coordinate.latitude,
                    "longitude": place!.coordinate.longitude,
                    "radius": Int(Double(self.desiredRadius) * 1609.34) // Miles to METERS
                    ] as [String : Any]
                
                Restaurant.searchNearby(options: options, success: { (restaurants) in
                    
                    self.nearbyRestaurants = restaurants
                    self.calculateDistancesForRestaurants()
                    self.showNearbyRestaurantsOnMap(restaurants: restaurants)
                    
                }, failure: { (error, reason) in
                    print(error, reason)
                })
                
                print("user selected place: \(place!.formattedAddress!)")
            }

            
        } else {
            
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
                    "radius": Int(Double(self.desiredRadius) * 1609.34) // Miles to METERS
                    ] as [String : Any]
                
                Restaurant.searchNearby(options: options, success: { (restaurants) in
                    
                    self.nearbyRestaurants = restaurants
                    self.calculateDistancesForRestaurants()
                    self.showNearbyRestaurantsOnMap(restaurants: restaurants)
                    
                }, failure: { (error, reason) in
                    print(error, reason)
                })
                
                print("user selected place: \(place!.formattedAddress!)")
            }
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

        //build bounds with location as center
        //
        let halfDistance = (Double(desiredRadius) * 1609.34) / 2
        
        var origin = currentLocation?.coordinate
        
        if let _ = selectedPlace {
            origin = selectedPlace?.coordinate
        }
        
        let southwestCoord = locationWithBearing(bearing: 225, distanceMeters: halfDistance, origin: origin!)
        let northeastCoord = locationWithBearing(bearing: 45, distanceMeters: halfDistance, origin: origin!)
        let distanceFilter = GMSCoordinateBounds(coordinate: southwestCoord, coordinate: northeastCoord)
        
        placesClient.autocompleteQuery(query, bounds: distanceFilter, filter: filter, callback: {(results, error) -> Void in
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
                    
                    self.tableView.frame = newFrame
                    
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

            if let _ = destinitation.restaurant {
                destinitation.restaurant = sender as? Restaurant
            } else {
                destinitation.place = sender as? GMSPlace
            }
        }
    }
    
    @IBAction func dismissToMap(segue : UIStoryboardSegue) {
        print("back to map")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6)
        
        let rbearing = bearing * .pi / 180.0
        
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(rbearing))
        let lon2 = lon1 + atan2(sin(rbearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
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

