//
//  myAnnotation.swift
//  PolyMaps
//
//  Created by Masato Nandate on 2/15/24.
//

import UIKit
import MapKit

class MyAnnotationView: MKAnnotationView{
    override init(annotation: MKAnnotation?, reuseIdentifier: String?){
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView(){
       //check if annotation is of class MyAnnotation
        if let myAnnotation = annotation as? MyAnnotation{
            image = UIImage(named: myAnnotation.imageName)
            
        }
        
    }
    
}
