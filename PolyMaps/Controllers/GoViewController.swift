//
//  GoViewController.swift
//  PolyMaps
//
//  Created by Masato Nandate on 3/10/24.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
class GoViewController : UIViewController {
    
    @IBOutlet var DestinationLabel: UILabel!
    @IBOutlet var DistanceLabel: UILabel!
    @IBOutlet var PointsLabel: UILabel!
    @IBOutlet var GoButton: UIButton!
    var destination: String? = ""
    var pointsCount = 0
    var totalDistance = 0.0
    //data that gets passed intermediately
    var destCoordinates: [CLLocationCoordinate2D]?
    var locationManager: CLLocationManager?
    var finalDestination: CLLocationCoordinate2D?
    var origin: CLLocation?
    var route: MKRoute?
    
    override func viewDidLoad() {
        getInitialDistance()
        self.DestinationLabel.text = "Destination: \(destination ?? "")"
        self.DistanceLabel.text = "Distance: \(totalDistance.rounded()) Meters"
        self.PointsLabel.text = "Number of Points: \(destCoordinates?.count ?? 0)"
        self.GoButton.setTitle("Start Route", for: .normal)
    }
    

    @IBAction func buttonTapped(_ sender: UIButton) {
        // Replace "YourSegueIdentifier" with the actual identifier you set for the segue in the storyboard
        performSegue(withIdentifier: "ARTransition", sender: self)
    }
    // Send data through a segway
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ARTransition"{
            if let destinationVC = segue.destination as? ARSceneController{
                //send data
                destinationVC.origin = self.origin
                destinationVC.finalDestination = self.finalDestination
                destinationVC.destCoordinates = self.destCoordinates
                destinationVC.locationManager = self.locationManager
                destinationVC.route = self.route
            }
        }
    }
    
    func getInitialDistance(){
        if let origin = self.origin, let destination = self.finalDestination{
            let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
            self.totalDistance = origin.distance(from: destinationLocation)
        }
    }
}

protocol GoViewControllerDelegate: AnyObject{
    func didDismissModalWithData(data: Any)
}
