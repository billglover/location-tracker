//
//  ViewController.swift
//  location-tracker
//
//  Created by Bill Glover on 11/06/2016.
//  Copyright © 2016 Bill Glover. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var broadcastToggle: UISwitch!
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startBroadcastingLocation() {
        if broadcastToggle.on {
            switch CLLocationManager.authorizationStatus() {
            case .AuthorizedAlways:
                print("AuthorizedAlways")
                locationManager.startUpdatingLocation()
            case .AuthorizedWhenInUse:
                print("AuthorizedWhenInUse")
                locationManager.startUpdatingLocation()
            case .Denied:
                print("Denied")
                stopBroadcastingLocation()
                let alertViewController = UIAlertController(title: "Denied", message: "You have denied access to your location. You will need to visit your privacy settings to enable access.", preferredStyle: .Alert)
                alertViewController.addAction(UIAlertAction(title: "Understood", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertViewController, animated: true, completion: nil)
            case .NotDetermined:
                print("NotDetermined")
                locationManager.requestAlwaysAuthorization()
            case .Restricted:
                print("Restricted")
                stopBroadcastingLocation()
            }
        }
    }
        
    func stopBroadcastingLocation() {
        broadcastToggle.on = false
        locationManager.stopUpdatingLocation()
    }
    

    // MARK:- User Action
    @IBAction func broadcastToggled(sender: UISwitch) {
        print("broadcastToggled to \(sender.on)")
        
        if sender.on {
            startBroadcastingLocation()
        } else {
            stopBroadcastingLocation()
        }
        
    }
    
    // MARK:- LocationManger Delegates
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("locationManager.didChangeAuthorizationStatus")
        
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            print("AuthorizedAlways")
            startBroadcastingLocation()
        case .AuthorizedWhenInUse:
            print("AuthorizedWhenInUse")
            startBroadcastingLocation()
        case .Denied:
            print("Denied")
            stopBroadcastingLocation()
        case .NotDetermined:
            print("NotDetermined")
            stopBroadcastingLocation()
        case .Restricted:
            print("Restricted")
            stopBroadcastingLocation()
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error.localizedDescription)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            print("Location: \(location.coordinate)")
        }
    }
}

