//
//  Visit.swift
//  location-tracker
//
//  Created by Bill Glover on 19/06/2016.
//  Copyright © 2016 Bill Glover. All rights reserved.
//

import Foundation
import CoreLocation

extension CLVisit {
    var asDictionary: NSDictionary {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = NSTimeZone.localTimeZone()
        
        let d: [String : AnyObject] = [
            "latitude" : self.coordinate.latitude,
            "longitude" : self.coordinate.longitude,
            "horizontalAccuracy" : self.horizontalAccuracy,
            "deviceTime" : formatter.stringFromDate(self.arrivalDate),
            "description" : "location"
        ]
        return d
    }
}