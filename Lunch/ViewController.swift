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
    var zoomLevel: Float = 15.0
    
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    var tableDataSource: GMSAutocompleteTableDataSource?
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    let keyboard = Typist.shared
    var searchTextField : SearchTextField? = nil
    var filterButton : UIButton?
    var dismissTapView : UIView?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewBottomLayoutConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        setupLocationServices()
        setupView()
        configureKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
    }
    
    func setupView() {
        self.tableView.isHidden = true
    }
    
    func setupMap() {
        
    }
    
    func setupSearch() {
        
        tableDataSource = GMSAutocompleteTableDataSource()
        tableDataSource?.delegate = self
        
        filterButton = UIButton(type: .system)
        filterButton?.frame = CGRect(x: view.frame.width - 58, y: 24, width: 38, height: 48)
        filterButton?.setImage(UIImage(named: "filter"), for: .normal)
        filterButton?.tintColor = .black
        filterButton?.addTarget(self, action: #selector(ViewController.showFilter), for: .touchUpInside)
        
        searchTextField = SearchTextField(frame: CGRect(x: 10, y: 20, width: view.frame.width - 20, height: 55))
        searchTextField?.borderStyle = .none
        searchTextField?.backgroundColor = .white
        searchTextField?.layer.masksToBounds = false
        searchTextField?.layer.shadowRadius = 1.0
        searchTextField?.layer.shadowColor = UIColor.black.cgColor
        searchTextField?.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        searchTextField?.layer.shadowOpacity = 0.5
        searchTextField?.layer.cornerRadius = 4.0
        searchTextField?.delegate = self
        searchTextField?.returnKeyType = UIReturnKeyType.search
        
        let attributes = [
            NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.5),
            NSFontAttributeName : UIFont(name: "AppleSDGothicNeo-UltraLight", size: 22)!
        ]
        
        searchTextField?.attributedPlaceholder = NSAttributedString(string: "Search for something delicious!", attributes:attributes)
        
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
                                                  zoom: zoomLevel)
            mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
            mapView.settings.myLocationButton = false
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mapView.isMyLocationEnabled = true
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
            
            listLikelyPlaces()
        }
    }
    
    func listLikelyPlaces() {
        
        // Clean up from previous sessions.
        likelyPlaces.removeAll()
        
        placesClient.currentPlace(callback: { (placeLikelihoods, error) in
            if let error = error {
                print("\(error.localizedDescription)")
                return
            }
            
            // Get likely places and add to the list.
            if let likelihoodList = placeLikelihoods {
                for likelihood in likelihoodList.likelihoods {
                    let place = likelihood.place
                    self.likelyPlaces.append(place)
                }
            }
        })
    }
    
    //  MARK:   UITextField Delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
            
        DispatchQueue.main.async {
            self.tableView.isHidden = false
            self.tableView.reloadData()
            //self.addDismissView()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        tableDataSource?.sourceTextHasChanged(string)
        return true
    }
    
    func showFilter() {
        performSegue(withIdentifier: "showResturants", sender: nil)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        searchTextField?.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performSegue(withIdentifier: "showResturants", sender: nil)
        return true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath) as! AddressCell
        let place = likelyPlaces[indexPath.row]
        
        cell.textLabel?.text = place.name
        cell.detailTextLabel?.text = place.formattedAddress
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likelyPlaces.count
    }
    
    //  MARK:   Typest Keyboard Observer
    
    func configureKeyboard() {
        keyboard
            .on(event: .willChangeFrame) { (options) in
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.tableViewBottomLayoutConstraint.constant += options.endFrame.height
                    })
                }
                
                print("New Keyboard Frame is \(options.endFrame).")
            }
            .on(event: .willHide) { (options) in
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.tableViewBottomLayoutConstraint.constant = 10
                    })
                }

                print("It took \(options.animationDuration) seconds to animate keyboard out.")
            }
            .start()
    }
    
    //  MARK: GMSMapViewDelegate Methods
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        DispatchQueue.main.async {
            var searchFrame = self.searchTextField?.frame
            searchFrame?.origin.y = -30
            UIView.animate(withDuration: 0.25, animations: { 
                self.searchTextField?.frame = searchFrame!
            })
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        DispatchQueue.main.async {
            var searchFrame = self.searchTextField?.frame
            searchFrame?.origin.y = 20
            UIView.animate(withDuration: 0.25, animations: {
                self.searchTextField?.frame = searchFrame!
            })
        }
    }
    
    func mapViewSnapshotReady(_ mapView: GMSMapView) {
        mapView.delegate = self
    }
    
    //  MARK: GMSAutocompleteTableDataSource Methods
    
    func didUpdateAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator off.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // Reload table data.
        tableView.reloadData()
    }
    
    func didRequestAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator on.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // Reload table data.
        tableView.reloadData()
    }
    
    //  MARK: Segue Methods
    
    @IBAction func dismissToMap(segue : UIStoryboardSegue) {
        print("back to map")
    }
}

extension ViewController: GMSAutocompleteTableDataSourceDelegate {
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error) {
        // TODO: Handle the error.
        print("Error: \(error)")
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didSelect prediction: GMSAutocompletePrediction) -> Bool {
        return true
    }
}

// Delegates to handle events for the location manager.
extension ViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        listLikelyPlaces()
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

class AddressCell : UITableViewCell {
    
    
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

