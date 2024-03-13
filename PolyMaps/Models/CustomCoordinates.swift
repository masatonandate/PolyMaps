//
//  CustomCoordinates.swift
//  PolyMaps
//
//  Created by Masato Nandate on 11/12/23.
//
//Need to connect this to mongoDB

import Foundation
class CustomCoordinates: Codable, Comparable{
    
    let latitude: Double
    let longitude: Double
    var title: String = ""
    var order: Int = 0
    var _distance : Double = 0
    var _loaded: Bool = false
    
    init(latitude: Double, longitude: Double, title: String = "", order: Int = 0, _distance: Double = 0, _loaded: Bool = false) {
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.order = order
        self._distance = _distance
        self._loaded = _loaded
    }
    
    var distance: Double{
        get{
            return _distance
        }
        set(newValue){
            self._distance = newValue
        }
    }
    
    var loaded: Bool{
        get{
            return _loaded
        }
        set(newValue){
            self._loaded = newValue
        }
    }
    
    static func < (lhs: CustomCoordinates, rhs: CustomCoordinates) -> Bool {
        return lhs.distance < rhs.distance
    }
    
    static func == (lhs: CustomCoordinates, rhs: CustomCoordinates) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
}


extension CustomCoordinates{
    static let sampleData: [CustomCoordinates]? = [
        CustomCoordinates(latitude: 35.304472, longitude: -120.658556, title: "Serenity Swing"),
        CustomCoordinates(latitude: 35.302807, longitude: -120.651689, title: "The P"),
        CustomCoordinates(latitude: 35.30236, longitude: -120.66199, title: "Special Cow"),
        CustomCoordinates(latitude: 35.300504, longitude: -120.663550, title: "Dexter Lawn"),
        CustomCoordinates(latitude: 35.2986685, longitude: -120.6599450, title: "The Rec"),
        CustomCoordinates(latitude: 35.30012, longitude: -120.66229, title: "Frank E. Pilling"),
        CustomCoordinates(latitude: 35.29491, longitude: -120.66275, title: "Masato's House")
        
        
    ]
}
