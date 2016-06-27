//
//  Location.swift
//  location-tracker
//
//  Created by Bill Glover on 22/06/2016.
//  Copyright © 2016 Bill Glover. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

class Location: Object {
    
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0
    dynamic var altitude: Double = 0.0
    dynamic var horizontalAccuracy: Double = -1.0
    dynamic var verticalAccuracy: Double = -1.0
    dynamic var deviceTime: NSDate = NSDate()
    dynamic var detail: String = ""
    
    convenience init(loc: CLLocation) {
        self.init()
        self.latitude = loc.coordinate.latitude
        self.longitude = loc.coordinate.longitude
        self.altitude = loc.altitude
        self.horizontalAccuracy = loc.horizontalAccuracy
        self.verticalAccuracy = loc.verticalAccuracy
        self.deviceTime = loc.timestamp
        self.detail = "location"
    }
    
    var asDictionary: NSDictionary {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = NSTimeZone.localTimeZone()
        
        let d: [String : AnyObject] = [
            "latitude" : latitude,
            "longitude" : longitude,
            "altitude" : altitude,
            "horizontalAccuracy" : horizontalAccuracy,
            "verticalAccuracy" : verticalAccuracy,
            "deviceTime" : formatter.stringFromDate(deviceTime),
            "description" : detail
        ]
        return d
    }
    
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
