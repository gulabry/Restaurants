//
//  ViewController.swift
//  Lunch
//
//  Created by Bryan Gula on 7/7/17.
//  Copyright © 2017 Gula, Inc. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController, UITextFieldDelegate {
    
    let keyboard = Typist.shared
    var searchTextField : SearchTextField? = nil
    
    var dismissTapView : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupView()
        configureKeyboard()
    }
    
    func setupMap() {
        
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = mapView
        
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
    }
    
    func setupView() {
        
    }
    
    func setupSearch() {
        
        searchTextField = SearchTextField(frame: CGRect(x: 10, y: view.frame.height - 100, width: view.frame.width - 20, height: 55))
        searchTextField?.borderStyle = .none
        searchTextField?.backgroundColor = .white
        searchTextField?.layer.masksToBounds = false
        searchTextField?.layer.shadowRadius = 1.0
        searchTextField?.layer.shadowColor = UIColor.black.cgColor
        searchTextField?.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        searchTextField?.layer.shadowOpacity = 0.5
        searchTextField?.layer.cornerRadius = 4.0
        searchTextField?.delegate = self
        
        let attributes = [
            NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.5),
            NSFontAttributeName : UIFont(name: "AppleSDGothicNeo-UltraLight", size: 22)!
        ]
        
        searchTextField?.attributedPlaceholder = NSAttributedString(string: "Search for something delicious!", attributes:attributes)

        //view.insertSubview(searchTextField!, at: 2)
        view.insertSubview(searchTextField!, aboveSubview: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSearch()
    }
    
    //  MARK:   UITextField Delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("tapped")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        searchTextField?.resignFirstResponder()
    }
    
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        searchTextField?.resignFirstResponder()
    }
    
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

    
    //  MARK:   Typest Keyboard Observer
    
    func configureKeyboard() {
        keyboard
            .on(event: .willShow) { (options) in
                
                
                var searchFrame = self.searchTextField?.frame
                searchFrame?.origin.y = 20
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.searchTextField?.frame = searchFrame!
                    })
                    self.addDismissView()
                }
                
                print("New Keyboard Frame is \(options.endFrame).")
            }
            .on(event: .willHide) { (options) in
                
                var searchFrame = self.searchTextField?.frame

                searchFrame?.origin.y = self.view.frame.height - 100
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25, animations: { 
                        self.searchTextField?.frame = searchFrame!
                    })
                    self.removeDismissView()
                }
                
                print("It took \(options.animationDuration) seconds to animate keyboard out.")
            }
            .start()
    }

    
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

