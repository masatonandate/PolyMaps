//
//  AdressCoordinates.swift
//  PolyMaps
//
//  Created by Masato Nandate on 10/28/23.
//

import Foundation

struct AddressCoordinates: Codable{
    enum CodingKeys: String, CodingKey{
        case lat
        case lon
        case displayName = "display_name"
        
    }
    var lat: Double?
    var lon: Double?
    var displayName: String?
    
    init(from decoder: Decoder) throws{
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let latString = try? container.decode(String.self, forKey: .lat) {
            lat = Double(latString)
        }else{
            lat = nil
        }
        if let lonString = try? container.decode(String.self, forKey: .lon){
            lon = Double(lonString)
        }else{
            lon = nil
        }
        self.displayName = try container.decode(String.self, forKey: .displayName)
    }
    
}

struct AddressArray: Codable{
    let results: [AddressCoordinates]?
}
