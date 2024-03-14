//
//  ViewController.swift
//  PolyMaps
//
//  Created by Masato Nandate on 10/16/23.
//

import UIKit
import SceneKit
import ARKit
import MapKit
import CoreLocation
import Contacts

class FirstViewController: UIViewController{
    @IBOutlet weak var mapView: MKMapView!
    //    @IBOutlet var searchBar: UISearchBar!

    @IBOutlet var searchText: CustomSearchBarViewContainerView!
    var route: MKRoute?
    var myGeoCoder = CLGeocoder()
    var showButton = true
    var coordinatePoints: [CLLocationCoordinate2D] = []
    var destination = ""
    
    let locationManager = CLLocationManager()
    
    fileprivate func setupLongPress() -> UILongPressGestureRecognizer {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPress.minimumPressDuration = 1
        longPress.delaysTouchesBegan = true
//        longPress.delegate = self
        return longPress
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var longPress = setupLongPress()
        mapView.delegate = self
        mapView.addGestureRecognizer(longPress)
        mapView.showsCompass = false
        locationManager.delegate = self
        searchText.textFieldDelegate = self
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        
        mapView.addSubview(compassButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //listen for current location
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        addCustomPOI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //fetch for coordinates based on an address
    func fetchCoordinates(address: String, completionHandler: @escaping ([AddressCoordinates]) -> Void){
        let url = "https://geocode.maps.co/search?"
        
        guard let url = URL(string: url + "q={\(address)}") else {return}
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: {(data, response,error) in
            do {
                if let error = error {
                    print("\(url) caused an error: \(error)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else{
                    print("Error with the response, unexpected status code \(String(describing: response))")
                    return
                }
                if let data = data{
                    let addressData = try JSONDecoder().decode([AddressCoordinates].self, from: data)
                    completionHandler(addressData)
                }
            }catch{
                print("Error decoding JSON: \(error)")
            }
        })
        task.resume()
    }
    
    func fetchGeoCoordinates(address: String){
        var destCoordinates : CLLocationCoordinate2D?
        myGeoCoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            if let error = error{
                print("Error cause by \(error)")
            }
            if let placemark = placemarks?.first{
                print("Even Works")
                destCoordinates = placemark.location?.coordinate ?? nil
            }
        })
    }
    
    //function to fetchDirections using MKDirections
    func fetchDirection(_ sourceCoordinates: CLLocationCoordinate2D, _ destCoordinates: CLLocationCoordinate2D){
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinates, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destCoordinates, addressDictionary: nil))
        request.transportType = .any
        request.requestsAlternateRoutes = true
        //make the call to calculate a route
        let directions = MKDirections(request: request)
        directions.calculate {[unowned self] response, error in
            guard let unwrappedResponse = response else {return}
            removeOldRoutes()
            removeOldARAnnotations()
            let firstRoute = unwrappedResponse.routes.first
            if let firstRoute = unwrappedResponse.routes.first{
                //adding the line to map
                self.route = firstRoute
                self.mapView.addOverlay(firstRoute.polyline)
                let mapSize = firstRoute.polyline.boundingMapRect.size
                let mapOrigin = firstRoute.polyline.boundingMapRect.origin
                let newBoundingMap = MKMapRect(origin: mapOrigin, size: MKMapSize(width: mapSize.width * 1.5, height: mapSize.height * 1.5))
                self.mapView.setVisibleMapRect(newBoundingMap, animated: true)
                //getting the in-between points and adding it to an array
                let mapPoints = firstRoute.polyline.points()
                let count = firstRoute.polyline.pointCount
                for i in 0..<count{
                    self.coordinatePoints.append(mapPoints[i].coordinate)
                    //Add points on map where the AR boxed would be
                    let ARAnnotation = MyAnnotation(coordinate: mapPoints[i].coordinate, imageName: "ARPin", type: "AR")
                    self.mapView.addAnnotation(ARAnnotation)
                }
//                self.goButton.isHidden = !showButton
                presentModalView()
                
            }
        }
    }
    
    //MARK: addCustomPOI
    func addCustomPOI(){
        guard let customLocations = CustomCoordinates.sampleData else {return}
        for customLocation in customLocations {
            let customCoordinate = CLLocationCoordinate2DMake(customLocation.latitude, customLocation.longitude)
            let customTitle = customLocation.title
            let custom = MyAnnotation(title: customTitle, coordinate: customCoordinate, imageName: "POIPin", type: "POI")
            self.mapView.addAnnotation(custom)
        }
    }
    
    //MARK: removeOldRoutes
    func removeOldRoutes(){
        let overlays = self.mapView.overlays
        self.mapView.removeOverlays(overlays)
    }
    
    //MARK: removeOldARAnnotations
    func removeOldARAnnotations(){
        let annotations: [MKAnnotation] = self.mapView.annotations
        for annotation in annotations {
            if let customAnnotation = annotation as? MyAnnotation{
                if customAnnotation.type == "AR"{
                    self.mapView.removeAnnotation(annotation)
                }
            }
        }
    }
    
    //MARK: Long Press Handler
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizer.State.ended{
            return
        }
        else if gestureRecognizer.state != UIGestureRecognizer.State.began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let touchCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let customAnnot = MyAnnotation(title: "Pressed Location", coordinate: touchCoordinate, imageName: "POIPin", type: "POI")
            self.mapView.addAnnotation(customAnnot)
            
        }
    }
    
    //MARK: - Presenting View Programatically
    func presentModalView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let destinationController = storyboard.instantiateViewController(withIdentifier: "GoViewController") as? GoViewController
        else { return }

        if let presentationController = destinationController.presentationController as? UISheetPresentationController {
            presentationController.detents = [.custom{context in 250}]
        }
        destinationController.origin = self.locationManager.location
        destinationController.finalDestination = self.coordinatePoints.last
        destinationController.destCoordinates = self.coordinatePoints
        destinationController.locationManager = self.locationManager
        destinationController.route = self.route
        destinationController.destination = self.title
        self.present(destinationController, animated: true)
    }
    
    @IBAction func unwind(_ seg: UIStoryboardSegue) {
    }
}

//MARK: UISearchBarDelegate
extension FirstViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        let dispatchGroup = DispatchGroup() //a way to do a pause() and continue() in Swift
        var myCoordinates: [AddressCoordinates] = []
        var sourceCoordinates: CLLocationCoordinate2D
        var destCoordinates: CLLocationCoordinate2D
        guard let text = searchBar.text else {return}
        guard let currLocation = locationManager.location?.coordinate else {return}
        print(text)
        dispatchGroup.enter()
        fetchCoordinates(address: text){[weak self] (destinationCoord) in
            if let firstCoordinate = destinationCoord.first{
                print("Latitude:", firstCoordinate.lat ?? "N/A")
                print("Longitude:", firstCoordinate.lon ?? "N/A")
            }else{
                print("No Coordinates Available")
            }
            myCoordinates = destinationCoord
            dispatchGroup.leave()
        }
        fetchGeoCoordinates(address: text)
        dispatchGroup.wait()
        destCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(myCoordinates.first?.lat ?? 0), longitude: CLLocationDegrees(myCoordinates.first?.lon ?? 0))
        sourceCoordinates = currLocation
        fetchDirection(sourceCoordinates, destCoordinates)
    }
}

//MARK: UITextFieldDelegate
extension FirstViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let dispatchGroup = DispatchGroup() //a way to do a pause() and continue() in Swift
        var myCoordinates: [AddressCoordinates] = []
        var sourceCoordinates: CLLocationCoordinate2D
        var destCoordinates: CLLocationCoordinate2D
        textField.resignFirstResponder()
        guard let text = textField.text else {return false}
        guard let currLocation = locationManager.location?.coordinate else {return false}
        dispatchGroup.enter()
        fetchCoordinates(address: text){[weak self] (destinationCoord) in
            if let firstCoordinate = destinationCoord.first{
                print("Latitude:", firstCoordinate.lat ?? "N/A")
                print("Longitude:", firstCoordinate.lon ?? "N/A")
            }else{
                print("No Coordinates Available")
            }
            myCoordinates = destinationCoord
            dispatchGroup.leave()
        }
        fetchGeoCoordinates(address: text)
        dispatchGroup.wait()
        destCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(myCoordinates.first?.lat ?? 0), longitude: CLLocationDegrees(myCoordinates.first?.lon ?? 0))
        sourceCoordinates = currLocation
        fetchDirection(sourceCoordinates, destCoordinates)
        return true
    }
}

//MARK: -CLLocationManagerDelegate
extension FirstViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locations = locations.last else {return}
        return
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let locations = self.locationManager.location else {return}
        let coordRegion = MKCoordinateRegion(center: locations.coordinate, latitudinalMeters: CLLocationDistance(100), longitudinalMeters: CLLocationDistance(100))
        mapView.setRegion(coordRegion, animated: true)
        mapView.showsUserLocation = true
    }
}

//MARK: -MKMapDelegate
extension FirstViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .green
        renderer.lineWidth = 4.0
        renderer.alpha = 1.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let currLocation = locationManager.location?.coordinate else {return}
        guard let destLocation = view.annotation?.coordinate else {return}
        if let title = view.annotation?.title as? String {
            self.title = title
        }
        fetchDirection(currLocation, destLocation)
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
    

