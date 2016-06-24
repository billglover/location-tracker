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
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        
    }
    
    override func viewWillAppear(animated: Bool) {
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        let realm = ad.realm
        token = realm.addNotificationBlock { notification, realm in
            self.updateCounters()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if token != nil {
            token!.stop()
        }
    }
    
    func updateCounters() {
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        let realm = ad.realm
        let locations = realm.objects(Location.self)
        let visits = realm.objects(Visit.self)
        self.locations = locations.count
        self.visits = visits.count
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func submitVisit(visit: CLVisit) {
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        let realm = ad.realm
        realm.beginWrite()
        realm.add(Visit(visit: visit))
        try! realm.commitWrite()
        
        let a = [visit.asDictionary]
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
        
        if body != nil {
            postLocationsWith(body!)
        }
    }
    
    func submitLocations(locations: [CLLocation]) {
        
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        let realm = ad.realm
        realm.beginWrite()
        for loc in locations {
            realm.add(Location(loc: loc))
        }
        try! realm.commitWrite()
        
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
        
        if body != nil {
            postLocationsWith(body!)
        }
    }
    
    func postLocationsWith(body: String) {
        //let url = NSURL(string: "https://locationapi.localtunnel.me/locations")
        let url = NSURL(string: "http://zhujia.dtdns.net:8080/locations")
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request){
            data, response, error in
            if(error != nil){
                print(error)
            }
            dispatch_async(dispatch_get_main_queue()){
                print((response as! NSHTTPURLResponse).statusCode)
                self.apiResponseLabel.text = "API Response: \((response as! NSHTTPURLResponse).statusCode)"
            }
            
        }
        task.resume()
    }
    
    
    
    // MARK:- User Action
    @IBAction func trackVisitsToggled(sender: UISwitch) {
        print("broadcastVisits to \(sender.on)")
        
        if sender.on {
            startBroadcastingVisits()
        } else {
            stopBroadcastingVisits()
        }
        
    }
    
    @IBAction func trackLocationToggled(sender: UISwitch) {
        print("broadcastLocations to \(sender.on)")
        
        if sender.on {
            startBroadcastingLocation()
        } else {
            stopBroadcastingLocation()
        }
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
        submitLocations(locations)
    }
    
    func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
        print("Visited: \(visit.coordinate) at \(visit.arrivalDate)")
        submitVisit(visit)
    }
}

