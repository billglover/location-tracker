//
//  Visit.swift
//  location-tracker
//
//  Created by Bill Glover on 22/06/2016.
//  Copyright © 2016 Bill Glover. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

class Visit: Object {
    
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0
    dynamic var horizontalAccuracy: Double = -1.0
    dynamic var deviceTime: NSDate = NSDate()
    dynamic var detail: String = ""
    
    convenience init(visit: CLVisit) {
        self.init()
        self.latitude = visit.coordinate.latitude
        self.longitude = visit.coordinate.longitude
        self.horizontalAccuracy = visit.horizontalAccuracy
        self.deviceTime = visit.arrivalDate
        self.detail = "visit"
    }
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
