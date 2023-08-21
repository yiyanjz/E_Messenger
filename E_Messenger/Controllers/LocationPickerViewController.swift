//
//  LocationPickerViewController.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/20/23.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    // completion paramaeter
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinates: CLLocationCoordinate2D?
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    // to display the location when clicked on in messages
    // isPickable seprates whether is send of view
    private var isPickable = true
    
    init(coordinates: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        if coordinates != nil {
            self.coordinates = coordinates
            self.isPickable = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isPickable {
            // create a send button
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonTapped))
            // let user interacted with the map
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(didTapMap(_:)))
            map.isUserInteractionEnabled = true
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        } else {
            // just show location
            guard let coordinates = self.coordinates else {
                return
            }
            // drop the pin
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        view.addSubview(map)
    }
    
    @objc func sendButtonTapped() {
        guard let coordinates = coordinates else {
            return
        }
        // means to go back one controller
        navigationController?.popViewController(animated: true)
        // pass in that data so it could be called
        completion?(coordinates)
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer) {
        // convert a tap to location in the world with long lat cord
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        // drop a pin on that tapped location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        
        // delete all previous annotations
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        map.addAnnotation(pin)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
}
