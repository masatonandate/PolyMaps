//
//  ARSceneView.swift
//  PolyMaps
//
//  Created by Masato Nandate on 10/22/23.
//

import Foundation
import ARKit
import SceneKit
import CoreLocation
import UIKit
import MapKit
class ARSceneController: UIViewController{
    
    @IBOutlet var DistanceIndicator: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var arView: ARSCNView!
    @IBOutlet var totalProgress: UIProgressView!
    //Data recieved from Segue
    var destCoordinates: [CLLocationCoordinate2D]?
    var locationManager: CLLocationManager?
    var finalDestination: CLLocationCoordinate2D?
    var origin: CLLocation?
    var route: MKRoute?
    var totalDistance : Double = 0
    var sortedCoordinates: [CustomCoordinates] = []
    var geoAnchor: Bool = false
    var renderPoint: Bool = false
    var renderCount = 0
    var arrowScene : SCNScene = SCNScene()
    var arrowNode: SCNNode = SCNNode()
    var northernAngle : Double = 0
    
    fileprivate func setupDistanceIndicator() {
        self.DistanceIndicator.layer.cornerRadius = 10
        self.DistanceIndicator.layer.masksToBounds = true
    }
    
    fileprivate func drawRoute() {
        if let route = route{
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            addARPointsToMap()
        }
    }
    
    fileprivate func instantiateArrow() {
        self.arrowScene = SCNScene(named: "art.scnassets/direction_arrow.scn")!
        self.arrowNode = arrowScene.rootNode.childNodes.first!.clone()
        self.arrowNode.name = "ArrowNode"
    }
    
    fileprivate func configureAR() {
        // Create a session configuration, check if ARGeoTracking is available in location
        ARGeoTrackingConfiguration.checkAvailability{ (available, error) in
            guard available else{
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                self.arView.session.run(configuration)
                print("ARGeoTracking Not Available")
                return
            }
            self.geoAnchor = true
            let configuration = ARGeoTrackingConfiguration()
            // Run the view's session
            self.arView.session.run(configuration)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDistanceIndicator()
        self.arView.isUserInteractionEnabled = false
        locationManager?.delegate = self
        locationManager?.startUpdatingHeading()
        arView.delegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
        getCustomCoordinates()
        testAngles()
        getInitialDistance()
        drawRoute()
        instantiateArrow()
        configureAR()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arView.session.pause()
        if isBeingDismissed{
            performSegue(withIdentifier: "unwindToMain", sender: self)
        }
    }
    
    //MARK: -Getting Initial Distance
    func getInitialDistance(){
        if let origin = self.origin, let destination = self.finalDestination{
            let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
            self.totalDistance = origin.distance(from: destinationLocation)
        }
    }
    
    //MARK: - Loading Point Method
    func addGeoAnchor(){
        findNearestAnchors()
        //Gets the three nearest coordinates
        if(!sortedCoordinates.isEmpty){
            for i in 0..<3{
                let custom = self.sortedCoordinates[i]
                if(custom._loaded == false){
                    let coordinate = CLLocationCoordinate2D(latitude: custom.latitude,longitude: custom.longitude)
                    print(coordinate)
                    let geoAnchor = ARGeoAnchor(coordinate: coordinate)
                    self.arView.session.add(anchor: geoAnchor)
                    custom._loaded = true
                }
            }
        }
    }
    
    func addNormalAnchor(){
        findNearestAnchors()
        //Gets the three nearest coordinates
        if(!sortedCoordinates.isEmpty && !reachedGoal()){
            let custom = self.sortedCoordinates[0]
            let order = custom.order
            removePassedPoints(order: order)
            self.DistanceIndicator.text = "Distance To Nearest Point: \(custom.distance.rounded()) Meters"
            if(custom._loaded == false && custom.distance <= 10){
                self.renderPoint = true
                custom._loaded = true
            }
        }
        else{
            self.DistanceIndicator.text = "Reached Destination:"
        }
    }
    
    //MARK: - getCustomCoordinates
    //initializes the array of customCoordinates from passed coordinates
    func getCustomCoordinates(){
        if let coordinateArray = destCoordinates{
            var order = 1
            for point in coordinateArray{
                let customCoord = CustomCoordinates(latitude: point.latitude, longitude: point.longitude, order: order)
                self.sortedCoordinates.append(customCoord)
                order += 1
            }
        }
    }
    
    //MARK: - findNearestAnchors
    //gets the distances, puts it into the customCoordiante array, and then sorts
    func findNearestAnchors(){
        if let locationMan = locationManager, let location = locationMan.location{
            for point in self.sortedCoordinates{
                let coord = CLLocation(latitude: point.latitude,longitude: point.longitude)
                let distance = location.distance(from: coord)
                point._distance = distance
            }
            self.sortedCoordinates = self.sortedCoordinates.sorted()
        }
    }
    
    
    //MARK: - addARPoints()
    func addARPointsToMap(){
        if let route = route{
            let mapPoints = route.polyline.points()
            let count = route.polyline.pointCount
            for i in 0..<count{
                //Add points on map where the AR boxed would be
                let ARAnnotation = MyAnnotation(coordinate: mapPoints[i].coordinate, imageName: "ARPin", type: "AR")
                self.mapView.addAnnotation(ARAnnotation)
            }
        }
    }
    
    //MARK: -Remove Old Points()
    func removePassedPoints(order: Int){
        var newCoordinates : [CustomCoordinates] = []
        for coordinate in sortedCoordinates {
            if coordinate.order > order{
                newCoordinates.append(coordinate)
            }
        }
        self.sortedCoordinates = newCoordinates
    }
    
    //MARK: - addArrow()
    func addArrow() -> SCNNode{
        let arrowScene = SCNScene(named: "art.scnassets/direction_arrow.scn")!
        let arrowNode = arrowScene.rootNode.childNodes.first!.clone()
        arrowNode.name = "ArrowNode"
        return arrowNode
    }
    
    
    func calculateBearingAngle(current: CustomCoordinates, destination: CustomCoordinates) -> Double {
        let lon1 = current.longitude
        let lat1 = current.latitude
        let lon2 = destination.longitude
        let lat2 = destination.latitude
        
        let dLon = (lon2 - lon1)
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1)
                * cos(lat2) * cos(dLon);

        let brng = atan2(y, x);
        let brngAngle = brng * 180 / .pi
        let normalBrngAngle = (brngAngle + 360).truncatingRemainder(dividingBy: 360)

        
        //convert bearing angle to radians
        let brngRadian = normalBrngAngle * (.pi/180)
        return brngRadian;
        
        
    }
    
    func testAngles(){
        for i in 0..<sortedCoordinates.count - 1 {
            print(calculateBearingAngle(current: sortedCoordinates[i], destination: sortedCoordinates[i+1]) * (180 / .pi))
        }
    }
    
    func reachedGoal() -> Bool{
        if let manager = self.locationManager, let location = manager.location, let final = self.finalDestination {
            let finalLocation = CLLocation(latitude: final.latitude, longitude: final.longitude)
            let distance = location.distance(from: finalLocation)
            print(distance)
            return distance < 5
        }
        return false
    }
    
}
    // MARK: - ARSCNViewDelegate
    extension ARSceneController: ARSCNViewDelegate{
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            if let lm = self.locationManager, let heading = lm.heading, self.renderPoint {
                let angle = calculateBearingAngle(current: sortedCoordinates[0], destination: sortedCoordinates[1])
                let phoneAngle = heading.trueHeading * (.pi / 180)
                let arrowAngle = angle - phoneAngle
                let newArrowNode = self.arrowNode.clone()
                let parentNode = SCNNode()
                newArrowNode.scale = SCNVector3(x:0.001, y: 0.001, z:0.001)
                newArrowNode.eulerAngles = SCNVector3(0, arrowAngle, 0)
                parentNode.addChildNode(newArrowNode)
                if !self.sortedCoordinates.isEmpty{
                    self.sortedCoordinates.remove(at: 0)
                }
                self.renderPoint = false
                return parentNode
            }
            else{
                return nil
            }
        }
    }
     

    
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        // Present an error message to the user
//        
//    }
//    
//    func sessionWasInterrupted(_ session: ARSession) {
//        // Inform the user that the session has been interrupted, for example, by presenting an overlay
//        
//    }
//    
//    func sessionInterruptionEnded(_ session: ARSession) {
//        // Reset tracking and/or remove existing anchors if consistent tracking is required
//        
//    }
    
//MARK: - CLLocationManagerDelegate
extension ARSceneController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, let destination = self.finalDestination{
            //setting region of map to show
            let currentRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(currentRegion, animated: true)
            //setting distance progress
            let finalLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
            let progress = 1.0 - (location.distance(from: finalLocation) / self.totalDistance)
            self.totalProgress.progress = Float(progress)
        }
        if geoAnchor == true{
            addGeoAnchor()
        }else{
            addNormalAnchor()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if (abs(self.northernAngle - newHeading.trueHeading) > 90){
            self.northernAngle = newHeading.trueHeading
            print(newHeading.trueHeading)
        }
    }
}

//MARK: - MKMapDelegate
extension ARSceneController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .green
        renderer.lineWidth = 4.0
        renderer.alpha = 1.0
        return renderer
    }
    
    
    //provides custom annotation view for each annotation displayed on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //want to ensure that the default user location annotation is not re-written, thus returns nil
        guard !(annotation is MKUserLocation) else{
            return nil
        }
        //check if there is a dequeable custom annotation
        let identifier = "myAnnotation";
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if(annotationView == nil){
            annotationView = MyAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        else{
            //if dequeable needs to actually set the annotation views annotation to be the passed annotation
            annotationView?.annotation = annotation
        }
        
        //want to change the size based on the custom point
        if let customAnnotation = annotationView?.annotation as? MyAnnotation {
            if customAnnotation.type == "POI"{
                annotationView?.frame.size = CGSize(width: 20, height: 30)
            }
            if customAnnotation.type == "AR" {
                annotationView?.frame.size = CGSize(width: 10, height: 10)
            }
        }
        return annotationView
    }
}
