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
    
    @IBOutlet var generalIndicator: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var arView: ARSCNView!
    //Data recieved from Segue
    @IBOutlet var ARIndicator: UILabel!
    var destCoordinates: [CLLocationCoordinate2D]?
    var locationManager: CLLocationManager?
    var sortedCoordinates: [CustomCoordinates] = []
    var geoAnchor: Bool = false
    var route: MKRoute?
    var renderPoint: Bool = false
    var renderCount = 0
    var arrowScene : SCNScene = SCNScene()
    var arrowNode: SCNNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.arView.showsStatistics = true
        self.arView.isUserInteractionEnabled = false
        self.arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        locationManager?.delegate = self
        arView.delegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
        getCustomCoordinates()
        if let route = route{
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            addARPointsToMap()
        }
        self.arrowScene = SCNScene(named: "art.scnassets/direction_arrow.scn")!
        self.arrowNode = arrowScene.rootNode.childNodes.first!.clone()
        self.arrowNode.name = "ArrowNode"
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arView.session.pause()
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
        if(!sortedCoordinates.isEmpty){
            let custom = self.sortedCoordinates[0]
            self.generalIndicator.text = "\(custom.distance), \(self.renderPoint)"
            self.ARIndicator.text = "Render Count \(self.renderCount), custom_loaded \(custom._loaded)"
            print(self.sortedCoordinates.count)
            if(custom._loaded == false && custom.distance <= 20){
                self.renderPoint = true
                custom._loaded = true
//                if let plane = raycastForHorizontalSurface(at: CGPoint(x: arView.bounds.midX, y: arView.bounds.midY), in: arView){
//                    print("Normal Anchor Placed")
//                    self.arView.session.add(anchor: plane)
//                }
            }
        }
    }
    
    //MARK: - getCustomCoordinates
    //initializes the array of customCoordinates from passed coordinates
    func getCustomCoordinates(){
        if let coordinateArray = destCoordinates{
            for point in coordinateArray{
                let customCoord = CustomCoordinates(latitude: point.latitude, longitude: point.longitude)
                self.sortedCoordinates.append(customCoord)
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
    
    //MARK: - addArrow()
    func addArrow() -> SCNNode{
        let arrowScene = SCNScene(named: "art.scnassets/direction_arrow.scn")!
        let arrowNode = arrowScene.rootNode.childNodes.first!.clone()
        arrowNode.name = "ArrowNode"
        return arrowNode
    }
    
    func addArrowToScene(){
        let angle = calculateAngleBetweenCoordinates(current: sortedCoordinates[0], destination: sortedCoordinates[1])
        let arrowScene = SCNScene(named: "art.scnassets/direction_arrow.scn")!
        let arrowNode = arrowScene.rootNode.childNodes.first!.clone()
        arrowNode.name = "ArrowNode"
        arrowNode.scale = SCNVector3(x: 0.001, y: 0.002, z: 0.001)
        arrowNode.eulerAngles = SCNVector3(x:0,y:Float(angle),z:0)
        self.arView.scene.rootNode.addChildNode(arrowNode)
        
    }
    
    //MARK: - calculateAngleBetweenCoordinates
    func calculateAngleBetweenCoordinates(current : CustomCoordinates, destination: CustomCoordinates) -> Double {
        let lat1 = current.latitude
        let lon1 = current.latitude
        
        let lat2 = destination.latitude
        let lon2 = destination.longitude
        
        // Earth radius in kilometers
        let earthRadius: Double = 6371.0
        
        // Convert latitude and longitude from degrees to radians
        let lat1Rad = lat1 * .pi / 180.0
        let lon1Rad = lon1 * .pi / 180.0
        let lat2Rad = lat2 * .pi / 180.0
        let lon2Rad = lon2 * .pi / 180.0
        
        // Convert latitude and longitude to Cartesian coordinates
        let x1 = earthRadius * cos(lat1Rad) * cos(lon1Rad)
        let y1 = earthRadius * cos(lat1Rad) * sin(lon1Rad)
        let z1 = earthRadius * sin(lat1Rad)
        
        let x2 = earthRadius * cos(lat2Rad) * cos(lon2Rad)
        let y2 = earthRadius * cos(lat2Rad) * sin(lon2Rad)
        let z2 = earthRadius * sin(lat2Rad)
        
        // Calculate the dot product of the two vectors
        let dotProduct = x1 * x2 + y1 * y2 + z1 * z2
        
        // Calculate the magnitudes of the two vectors
        let magnitude1 = sqrt(x1 * x1 + y1 * y1 + z1 * z1)
        let magnitude2 = sqrt(x2 * x2 + y2 * y2 + z2 * z2)
        
        // Calculate the angle in radians
        let angle = acos(dotProduct / (magnitude1 * magnitude2))
        
//        // Convert angle from radians to degrees
//        let angleDegrees = angle * 180.0 / .pi
        
        //return as radians
        return angle
    }
    //MARK: - raycastForHorizontalSurface
    func raycastForHorizontalSurface(at point: CGPoint, in sceneView: ARSCNView) -> ARAnchor? {
        guard let rayQuery = sceneView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .horizontal) else{return nil}
        guard let raycastResult = sceneView.session.raycast(rayQuery).first else {return nil}
        // Check if the raycast hit a valid horizontal plane
        guard let planeAnchor = raycastResult.anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal else {
            return nil
        }
        // Return the ARAnchor representing the horizontal surface
        print("finished raycast")
        return planeAnchor
    }
    
}
    // MARK: - ARSCNViewDelegate
    extension ARSceneController: ARSCNViewDelegate{
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            if self.renderPoint {
                let angle = calculateAngleBetweenCoordinates(current: sortedCoordinates[0], destination: sortedCoordinates[1])
                let newArrowNode = self.arrowNode.clone()
                self.renderPoint = false
                let parentNode = SCNNode()
//                let sphere = SCNSphere(radius: 0.1)
//                let newArrowNode = SCNNode(geometry: sphere)
                newArrowNode.scale = SCNVector3(x:0.001, y: 0.001, z:0.001)
                newArrowNode.eulerAngles = SCNVector3(0, angle, 0)
                parentNode.addChildNode(newArrowNode)
                self.sortedCoordinates.remove(at: 0)
                return parentNode
            }
            else{
                return nil
            }
        }
        
//       func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//           if self.renderPoint == true{
//               let angle = calculateAngleBetweenCoordinates(current: sortedCoordinates[0], destination: sortedCoordinates[1])
//                NSLog("view delgate hit")
//                self.renderPoint = false
//                print("\(angle)")
//                let newArrowNode = self.arrowNode.clone()
//                newArrowNode.scale = SCNVector3(x: 0.005, y: 0.001, z: 0.005)
//                newArrowNode.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
//                newArrowNode.eulerAngles = SCNVector3(0, angle, 0)
//                let exampleSphere = SCNNode(geometry: SCNSphere(radius: 0.2))
//                self.arView.scene.rootNode.addChildNode(exampleSphere)
//                self.renderCount += 1
//                node.addChildNode(newArrowNode)
//                sortedCoordinates[0].loaded = true
//           }
//        }
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
        if let location = locations.last{
            let currentRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(currentRegion, animated: true)
        }
        if geoAnchor == true{
            addGeoAnchor()
        }else{
            addNormalAnchor()
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
