//
//  MyAnnotation.swift
//  PolyMaps
//
//  Created by Masato Nandate on 2/15/24.
//

import Foundation
import MapKit

//This does not actually render the view, just makes the object
class MyAnnotation:NSObject, MKAnnotation{
    var title : String?
    var coordinate : CLLocationCoordinate2D
    var imageName : String
    var type: String
    
    init(title: String? = nil, coordinate: CLLocationCoordinate2D, imageName: String, type : String) {
        self.title = title
        self.coordinate = coordinate
        self.imageName = imageName
        self.type = type
    }
}
