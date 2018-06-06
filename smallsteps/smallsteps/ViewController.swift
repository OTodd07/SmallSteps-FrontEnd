//
//  ViewController.swift
//  smallsteps
//
//  Created by Jin Sun Park on 30/05/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, HandleMapSearch{
    var selectedPin:MKPlacemark? = nil
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var menuButton: UIButton!
    
    var resultSearchController:UISearchController? = nil
    var userId: Int = 0
    let manager = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        map.setRegion(region, animated: true)
        
        self.map.showsUserLocation = true
        map.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MapKit Setup
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        //Location Search Table Setup
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        locationSearchTable.handleMapSearchDelegate = self
        
        //Search Bar Setup
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Set Your Destination"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        //Set the map view in locationSearchTable
        locationSearchTable.map = map
        
        //Map Annotations
        map.register(LocationPointerView.self,
                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        let artwork = LocationPointer(title: "9AMers",
                              subtitle: "Huxley Building",
                              discipline: "Just Finished",
                              coordinate: CLLocationCoordinate2D(latitude: 51.4989034, longitude: -0.1811814))
        map.addAnnotation(artwork)
        
        let artwork2 = LocationPointer(title: "Mumsnetters",
                               subtitle: "Royal College of Art",
                               discipline: "Not Started",
                               coordinate: CLLocationCoordinate2D(latitude: 51.5011441, longitude: -0.1814734))
        map.addAnnotation(artwork2)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func getDirections(){
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: selectedPin!)
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: {(response, error) in
            
            if error != nil {
                print("Could not obtain directions!")
            } else {
                self.showRoute(response!)
            }
        })
    }
    
    func showRoute(_ response: MKDirectionsResponse) {
        print("showing route!")
        for route in response.routes {
            map.add(route.polyline,
                         level: MKOverlayLevel.aboveRoads)
//            for step in route.steps {
//                print(step.instructions)
//            }
        }
        self.fitAll(showGroups: true)
    }
    func mapView(_ mapView: MKMapView, rendererFor
        overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //so we don't modify the standard user location
            return nil
        }
        let reuseId = "Pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? LocationPointerView
        pinView = LocationPointerView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.canShowCallout = true
        
        let smallSquare = CGSize(width: 30, height: 30)
        let directionButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        directionButton.setBackgroundImage(#imageLiteral(resourceName: "walking"), for: .normal)
        directionButton.addTarget(self, action: #selector(self.getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = directionButton
 
        let infoButton = UIButton(frame: CGRect(origin: CGPoint.zero,
                                                size: CGSize(width: 30, height: 30)))
        infoButton.setBackgroundImage(UIImage(named: "info"), for: UIControlState())
        infoButton.addTarget(self, action: #selector(ViewController.displayInfo), for: .touchUpInside)
        pinView?.rightCalloutAccessoryView = infoButton
        
        return pinView
    }
    
    func dropPinZoomIn(placemark:MKPlacemark){
        //Clear previous pin and overlay
        map.removeOverlays(map.overlays)

        if(selectedPin != nil){
            for annotation in map.annotations {
                if (annotation.coordinate.latitude == selectedPin!.coordinate.latitude &&
                    annotation.coordinate.longitude == selectedPin!.coordinate.longitude){
                    map.removeAnnotation(annotation)
                }
            }
        }
        
        // save the pin so we can find directions to it later
        selectedPin = placemark
        
        var subtitle = ""
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            subtitle = "\(city), \(state)"
        }
        let annotation = LocationPointer(title: placemark.name!, subtitle: subtitle, discipline: "", coordinate: placemark.coordinate)
        map.addAnnotation(annotation)
        
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        map.setRegion(region, animated: true)
        }
    
    //Fits all pins on the map to the map view
    func fitAll(showGroups: Bool) {
        var zoomRect = MKMapRectNull;
        for annotation in map.annotations {
            if showGroups || (annotation as? LocationPointer)?.discipline == "" {
                let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
                let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.01, 0.01);
                zoomRect = MKMapRectUnion(zoomRect, pointRect);
            }
        }
        map.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsetsMake(40, 40, 40, 40), animated: true)
    }
    
    @objc func displayInfo(){
        performSegue(withIdentifier: "displayGroupInfo", sender: self)
    }
}

