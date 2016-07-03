//
//  ViewController.swift
//  location-tracker
//
//  Created by Bill Glover on 11/06/2016.
//  Copyright © 2016 Bill Glover. All rights reserved.
//

import UIKit
import CoreLocation
import RealmSwift

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var apiResponseLabel: UILabel!
    @IBOutlet weak var trackVisitsToggle: UISwitch!
    @IBOutlet weak var visitCounter: UILabel!
    @IBOutlet weak var locationCounter: UILabel!
    @IBOutlet weak var trackLocationToggle: UISwitch!
    let locationManager = CLLocationManager()
    var token: NotificationToken?
    
    var visits :Int {
        set {
            visitCounter.text = "\(newValue) visits"
        }
        get {
            let ad = UIApplication.sharedApplication().delegate as! AppDelegate
            let realm = ad.realm
            return realm.objects(Visit.self).count
        }
    }
    
    var locations :Int {
        set {
            locationCounter.text = "\(newValue) points"
        }
        get {
            let ad = UIApplication.sharedApplication().delegate as! AppDelegate
            let realm = ad.realm
            return realm.objects(Location.self).count
        }
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        restoreSwitchStates();
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.saveSwitchStates), name: "kSaveSwitchStatesNotification", object: nil);
        
        locationManager.delegate = self
        
    }
    
    override func viewWillAppear(animated: Bool) {
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        let realm = ad.realm
        token = realm.addNotificationBlock { notification, realm in
            self.realmDidChange(realm)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if token != nil {
            token!.stop()
        }
    }
    
    func updateCountersFromRealm(realm: Realm) {
        let locations = realm.objects(Location.self)
        let visits = realm.objects(Visit.self)
        self.locations = locations.count
        self.visits = visits.count
    }
    

    
    func startBroadcastingVisits() {
        if trackVisitsToggle.on {
            switch CLLocationManager.authorizationStatus() {
            case .AuthorizedAlways:
                print("AuthorizedAlways")
                locationManager.startMonitoringVisits()
            case .AuthorizedWhenInUse:
                print("AuthorizedWhenInUse")
                locationManager.startMonitoringVisits()
            case .Denied:
                print("Denied")
                stopBroadcastingVisits()
                let alertViewController = UIAlertController(title: "Denied", message: "You have denied access to your location. You will need to visit your privacy settings to enable access.", preferredStyle: .Alert)
                alertViewController.addAction(UIAlertAction(title: "Understood", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertViewController, animated: true, completion: nil)
            case .NotDetermined:
                print("NotDetermined")
                locationManager.requestAlwaysAuthorization()
            case .Restricted:
                print("Restricted")
                stopBroadcastingVisits()
            }
        }
    }
    
    func startBroadcastingLocation() {
        if trackLocationToggle.on {
            switch CLLocationManager.authorizationStatus() {
            case .AuthorizedAlways:
                print("AuthorizedAlways")
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.allowDeferredLocationUpdatesUntilTraveled(CLLocationDistanceMax, timeout: CLTimeIntervalMax)
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                locationManager.pausesLocationUpdatesAutomatically = false
                locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
                locationManager.startUpdatingLocation()
            case .AuthorizedWhenInUse:
                print("AuthorizedWhenInUse")
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.allowDeferredLocationUpdatesUntilTraveled(CLLocationDistanceMax, timeout: CLTimeIntervalMax)
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                locationManager.pausesLocationUpdatesAutomatically = false
                locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
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
    
    func stopBroadcastingVisits() {
        trackVisitsToggle.on = false
        locationManager.stopMonitoringVisits()
    }
    
    func stopBroadcastingLocation() {
        trackLocationToggle.on = false
        locationManager.stopUpdatingLocation()
    }
    
    
    
    
    
    // MARK:- Realm Operations
    func queueLocations(locations: [CLLocation]) {
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        let realm = ad.realm
        realm.beginWrite()
        for loc in locations {
            realm.add(Location(loc: loc))
        }
        try! realm.commitWrite()
    }
    
    func queueVisit(visit: CLVisit) {
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        let realm = ad.realm
        realm.beginWrite()
        realm.add(Visit(visit: visit))
        try! realm.commitWrite()
    }
    
    func realmDidChange(realm: Realm) {
        submitLocationsFromRealm(realm)
        submitVisitsFromRealm(realm)
        updateCountersFromRealm(realm)
    }
    
    func submitLocationsFromRealm(realm: Realm) {
        
        let locations = realm.objects(Location.self)
        
        // if there are no queued locations we don't need to do anything
        if locations.count > 0 {
            
            print("Queued Locations: \(locations.count)")
            
            // convert Results<Location> to JSON
            let a = locations.map({$0.asDictionary})
            var body: String?
            
            do {
                let opts = NSJSONWritingOptions()
                let data = try NSJSONSerialization.dataWithJSONObject(a, options: opts)
                
                body = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
            }
            catch let e as NSException {
                print(e.reason!)
            }
            catch let e as NSError {
                print(e.localizedDescription)
            }
            
            // check that we have a JSON string and the submit
            if body != nil {
                
                // create the POST request
                //let url = NSURL(string: "http://zhujia.dtdns.net:8080/locations")
                let url = NSURL(string: "https://api.billglover.me/locations")
                let session = NSURLSession.sharedSession()
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                request.HTTPBody = body!.dataUsingEncoding(NSUTF8StringEncoding)
        
                // create the submission task
                let task = session.dataTaskWithRequest(request){
                    data, response, error in
                    if(error != nil){
                        print(error)
                    } else {
                        dispatch_async(dispatch_get_main_queue()){
                            let statusCode = (response as! NSHTTPURLResponse).statusCode
                            print("API Response: \(statusCode)")
                            self.apiResponseLabel.text = "API Response: \(statusCode)"
                            
                            // if successful delete from realm
                            if statusCode == 201 {
                                print("Locations submitted successfully")
                                
                                print("Attempting to remove from local queue")
                                realm.beginWrite()
                                realm.delete(locations)
                                try! realm.commitWrite()
                                print("Locations removed from queue successfully")
                            }
                        }
                    }
                }
                
                // kick off the task
                task.resume()
        
            } else {
                print("Unexpectedly came across an empty JSON payload when trying to submit Locations")
            }
        }
    }
    
    func submitVisitsFromRealm(realm: Realm) {
        
        let visits = realm.objects(Visit.self)
        
        // if there are no queued visits we don't need to do anything
        if visits.count > 0 {
            
            print("Queued Visits: \(visits.count)")
            
            // convert Results<Visit> to JSON
            let a = visits.map({$0.asDictionary})
            var body: String?
            
            do {
                let opts = NSJSONWritingOptions()
                let data = try NSJSONSerialization.dataWithJSONObject(a, options: opts)
                
                body = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
            }
            catch let e as NSException {
                print(e.reason!)
            }
            catch let e as NSError {
                print(e.localizedDescription)
            }
            
            // check that we have a JSON string and the submit
            if body != nil {
                
                // create the POST request
                //let url = NSURL(string: "http://zhujia.dtdns.net:8080/locations")
                let url = NSURL(string: "https://api.billglover.me/locations")
                let session = NSURLSession.sharedSession()
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                request.HTTPBody = body!.dataUsingEncoding(NSUTF8StringEncoding)
                
                // create the submission task
                let task = session.dataTaskWithRequest(request){
                    data, response, error in
                    if(error != nil){
                        print(error)
                    } else {
                        dispatch_async(dispatch_get_main_queue()){
                            let statusCode = (response as! NSHTTPURLResponse).statusCode
                            print("API Response: \(statusCode)")
                            self.apiResponseLabel.text = "API Response: \(statusCode)"
                            
                            // if successful delete from realm
                            if statusCode == 201 {
                                print("Visits submitted successfully")
                                
                                print("Attempting to remove from local queue")
                                realm.beginWrite()
                                realm.delete(visits)
                                try! realm.commitWrite()
                                print("Visits removed from queue successfully")
                            }
                        }
                    }
                }
                
                // kick off the task
                task.resume()
                
            } else {
                print("Unexpectedly came across an empty JSON payload when trying to submit Visits")
            }
        }
    }


    
    
    
    
    // MARK:- User Action
    @IBAction func trackVisitsToggled(sender: UISwitch) {
        print("broadcastVisits to \(sender.on)")
        saveSwitchStates()
        
        if sender.on {
            startBroadcastingVisits()
        } else {
            stopBroadcastingVisits()
        }
        
    }
    
    @IBAction func trackLocationToggled(sender: UISwitch) {
        print("broadcastLocations to \(sender.on)")
        saveSwitchStates()
        
        if sender.on {
            startBroadcastingLocation()
        } else {
            stopBroadcastingLocation()
        }
    }
    
    func restoreSwitchStates() {
        print("restoring switch states")
        trackVisitsToggle!.on = NSUserDefaults.standardUserDefaults().boolForKey("trackVisitsToggle")
        trackLocationToggle!.on = NSUserDefaults.standardUserDefaults().boolForKey("trackLocationToggle")
    }
    
    func saveSwitchStates() {
        print("saving switch states")
        NSUserDefaults.standardUserDefaults().setBool(trackVisitsToggle!.on, forKey: "trackVisitsToggle")
        NSUserDefaults.standardUserDefaults().setBool(trackLocationToggle!.on, forKey: "trackLocationToggle")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func postLocationPressed(sender: UIButton) {
        print("postLocationPressed")
        
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            locationManager.requestLocation()
        case .AuthorizedWhenInUse:
            locationManager.requestLocation()
        case .Denied:
            print("Denied")
        case .NotDetermined:
            print("NotDetermined")
        case .Restricted:
            print("Restricted")
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
        for loc in locations {
            print("Located: \(loc.coordinate) at \(loc.timestamp)")
        }
        queueLocations(locations)
    }
    
    func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
        print("Visited: \(visit.coordinate) at \(visit.arrivalDate)")
        queueVisit(visit)
    }
}

