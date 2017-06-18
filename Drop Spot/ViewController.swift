//
//  FirstViewController.swift
//  yuri
//
//  Created by John Konderla on 5/20/17.
//  Copyright © 2017 John Konderla. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Foundation

class ViewController: UIViewController, GMSMapViewDelegate, InteractWithRoot {
    
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    var tappedMarker = GMSMarker()
    var infoWindow = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
    let bottomSheetVC = BottomSheetViewController()
    let baseURL = "http://dev.4tay.xyz:8080/yuri/api/location"
    var postingHash = ""
    
    var mycustomView: UIView!
    var hashInput: UITextField!
    
    var sentFromBottomSheet:String?
    var searchHash = ""
    
    var locationArray: Array<Any> = []
    
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    var oldDotID = ""
    var dotColor = ""
    struct yuriKeys {
        static let oldDotID = "oldDotID"
        static let dotColor = "dotColor"
    }
    let storage = UserDefaults.standard
    
    // Update the map once the user has made their selection.
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        // Clear the map.
        mapView.clear()
        
        // Add a marker to the map.
        if selectedPlace != nil {
            let marker = GMSMarker(position: (self.selectedPlace?.coordinate)!)
            marker.title = selectedPlace?.name
            marker.snippet = selectedPlace?.formattedAddress
            marker.map = mapView
        }
        
        //listLikelyPlaces()
    }
    
    @IBAction func sendLocation(_ sender: Any) {
        postingHash = ""
        putLocation()
    }
    func putLocation() {
        //get location of the user.
        let lat = locationManager.location?.coordinate.latitude
        print(lat ?? "no lat")
        let lng = locationManager.location?.coordinate.longitude
        print(lng ?? "no lng")
        print("my potential dotID is \(oldDotID)")
        let put = (baseURL + "?lng="+(lng?.description)!+"&lat="+(lat?.description)!+"&oldDotID=\(oldDotID)&colorCode=3&hash="+postingHash)
        print(put)
        postingHash = ""
        let putURL = URL(string: put)
        
        var request:URLRequest = URLRequest(url:putURL!)
        request.httpMethod = "PUT"
        URLSession.shared.dataTask(with:request) { (data, response, error) in
            if error != nil {
                print("error:",error.debugDescription)
            } else {
                //print("here is my response \(response)")
                //print("here is my data \(data?.description)")
                let parasedData = String(data: data!, encoding: String.Encoding.utf8) as String!
                if let unwrapped = parasedData {
                    print("here is my actual data: \(unwrapped)")
                    self.storage.set(unwrapped, forKey: yuriKeys.oldDotID)
                }
            }
            DispatchQueue.main.async {
                self.movedMapGetLocals()
            }
            }.resume()
    }
    @IBAction func addHash(_ sender: Any) {
        loadCustomViewIntoController()
        
        print("pushed new button!")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addBottomSheetView()
        //self.mapView.addSubview(self.makeSendLocation(text: "👍"))
        self.mapView.addSubview(self.makeHashButton(text: "taggggg"))
        infoWindow.backgroundColor = UIColor.blue
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        let mapInsets = UIEdgeInsets(top: 0, left: 0, bottom: 135, right: 0)
        mapView.padding = mapInsets
        mapView.setMinZoom(10, maxZoom: 20)
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true
        
        mapView.delegate = self
        // Getting my saved values
        if let oldID = storage.string(forKey: yuriKeys.oldDotID) {
            oldDotID = oldID
            print("My ID is: \(oldDotID)")
        }
        if let color = storage.string(forKey: yuriKeys.dotColor) {
            dotColor = color
            print(dotColor)
        }
        
        
    }
    func setHash(hash: String) {
        self.sentFromBottomSheet = hash
        if let valueToDisplay = sentFromBottomSheet {
            print("Value from bottomSheet = \(valueToDisplay)")
            searchHash = valueToDisplay
            movedMapGetLocals()
        } else {
            print("no data from bottomSheet")
        }
    }
    func mapView(_ mapViewIdle: GMSMapView, idleAt position: GMSCameraPosition) {
        
        movedMapGetLocals()
    }
    
    func movedMapGetLocals() {
        let latCenter = self.mapView.camera.target.latitude
        let lngCenter = self.mapView.camera.target.longitude
        
        let visableRegion: GMSVisibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: visableRegion.nearLeft, coordinate: visableRegion.farRight)
        let latNorthEast = bounds.northEast.latitude
        let lngNorthEast = bounds.northEast.longitude
        
        
        
        print("my lat \(latNorthEast), my lng \(lngNorthEast)")
        let lat = Float(latCenter) - Float(latNorthEast)
        let lng = Float(lngCenter) - Float(lngNorthEast)
        
        var range: Float = 0
        if(abs(lat) > abs(lng)) {
            range = abs(Float(lat))
        } else {
            range = abs(Float(lng))
        }
        //print("lng: \(Float(position.target.longitude)) lat: \(Float(position.target.latitude)) range: \(range)")
        
        let urlString = "\(baseURL)?range=\(range)&lng=\(lngCenter)&lat=\(latCenter)&hash=\(searchHash)"
        //reset the search hash
        searchHash = ""
        
        print("here is my whole thing!", urlString)
        
        let url = URL(string: urlString)
        mapView.clear()
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "random other error....")
            } else {
                var locationArray = [[String: Any]]()
                
                do {
                    if let data = data,
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let locations = json["locations"] as? [[String: Any]] {
                        for location in locations {
                            var locationDict: [String: Any] = [:]
                            if let lat = location["lat"] as? Float {
                                locationDict["lat"] = lat
                                if let lng = location["lng"] as? Float {
                                    locationDict["lng"] = lng
                                    let distanceTo = self.getDistance(remoteDistance: CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng)))
                                    locationDict["distanceTo"] = distanceTo
                                    print("distance to \(distanceTo)")
                                }
                            }
                            if let id = location["checkinID"] as? Int {
                                locationDict["checkinID"] = id
                            }
                            if let colorCode = location["colorCode"] as? Int {
                                locationDict["colorCode"] = colorCode
                            }
                            if let hashTag = location["hash"] as? String {
                                locationDict["hash"] = hashTag
                            }
                            
                            locationArray.append(locationDict)
                        }
                    }
                } catch {
                    print("Error deserializing JSON: \(error)")
                }
                self.updateMapWithLocations(array: locationArray)
                
            }
            
            }.resume()
        
    }
    
    func updateMapWithLocations(array: [[String: Any]]) {
        DispatchQueue.main.async {
            for local in array {
                if let lat = local["lat"] as? Float{
                    let lng = local["lng"] as? Float ?? 12.00
                    let id = local["checkinID"] as? Int ?? 101101
                    let colorCode = local["colorCode"] as? Int ?? 101101
                    let hashTag = local["hash"] as? String ?? "noHash"
                    print("checkinID:", id, "lat:", lat, "lng:", lng, "colorCode:", colorCode, "hash:", hashTag)
                    
                    let positions = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
                    
                    let marker = GMSMarker()
                    
                    marker.position = positions
                    
                    marker.isTappable = true
                    marker.tracksInfoWindowChanges = true
                    marker.title = hashTag
                    
                    
                    switch colorCode{
                    case 1:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "bluedot")
                    case 2:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "reddot")
                    case 3:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "greendot")
                    case 4:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "yellowdot")
                    case 5:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "orangedot")
                    case 6:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "pinkdot")
                    case 7:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "purpledot")
                    case 8:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "navydot")
                    default:
                        print("colorCode was a", colorCode)
                        marker.icon = #imageLiteral(resourceName: "bluedot")
                    }
                    
                    marker.map = self.mapView
                    
                }
            }
            self.bottomSheetVC.addLocations(locations: array)
        }
    }
    
    
    func makeSendLocation(text:String) -> UIButton {
        let locationButton = UIButton(type: UIButtonType.system)
        locationButton.frame = CGRect(x: view.frame.size.width-(locationButton.frame.size.width+65), y: view.frame.size.height-(locationButton.frame.size.height+140), width: 55, height: 55)
        locationButton.setBackgroundImage(#imageLiteral(resourceName: "ic_launcher"), for: .normal)
        locationButton.addTarget(self, action: #selector(sendLocation), for: .touchUpInside)
        return locationButton
        
    }
    
    func makeHashButton(text:String) -> UIButton {
        let locationButton = UIButton(type: UIButtonType.system)
        locationButton.frame = CGRect(x: view.frame.size.width-(locationButton.frame.size.width+65), y: view.frame.size.height-(locationButton.frame.size.height+270), width: 55, height: 55)
        locationButton.setBackgroundImage(#imageLiteral(resourceName: "ic_launcher"), for: .normal)
        locationButton.addTarget(self, action: #selector(addHash), for: .touchUpInside)
        return locationButton
        
    }
    
    func getDistance(remoteDistance: CLLocation) -> String {
        var newNumber = ""
        if let currentLocal = self.locationManager.location {
            
            let distance = currentLocal.distance(from: remoteDistance)
            
            if (distance < 10) {
                newNumber = "You're close!"
            }
            else if(distance < 500){
                let rounded = (distance * 3.28084).rounded()
                newNumber = String(rounded) + " feet"
            }
            else {
                let rounded = (((distance / 1609.34) * 10).rounded() / 10)
                newNumber = String(rounded) + " miles"
            }
        }
        
        return newNumber
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let title: String = marker.title!
        
        let markerPosition = CLLocation(latitude: CLLocationDegrees(marker.position.latitude), longitude: CLLocationDegrees(marker.position.longitude))
        
        bottomSheetVC.topLabel.text = title
        bottomSheetVC.distanceLabel.text = getDistance(remoteDistance: markerPosition)
        print("didTap was called")
        return false
    }
    
    
    func addBottomSheetView() {
        self.addChildViewController(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParentViewController: self)
        
        let height = view.frame.height
        let width  = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
        
        self.view.bringSubview(toFront: bottomSheetVC.view)
        bottomSheetVC.delegate = self
    }
    
    func loadCustomViewIntoController() {
        mycustomView = UIView(frame: CGRect(x: 10, y: (view.frame.size.height / 5), width: view.frame.size.width - 20, height: view.frame.size.height / 5))
        
        mycustomView.backgroundColor = UIColor.white
        
        self.view.addSubview(mycustomView)
        self.view.bringSubview(toFront: mycustomView)
        
        mycustomView.isHidden = false
        
        //add text field
        hashInput = UITextField(frame: CGRect(x: 0, y: mycustomView.frame.height / 4, width: mycustomView.frame.width, height: mycustomView.frame.height / 3))
        hashInput.placeholder = "#"
        hashInput.backgroundColor = UIColor.white
        
        mycustomView.addSubview(hashInput)
        hashInput.becomeFirstResponder()
        
        
        let okayButton = UIButton(frame: CGRect(x: 0, y: mycustomView.frame.height - 50, width: mycustomView.frame.width / 2, height: 50))
        okayButton.backgroundColor = UIColor.white
        
        // here we are adding the button its superView
        mycustomView.addSubview(okayButton)
        
        okayButton.addTarget(self, action: #selector(self.okButtonImplementation), for:.touchUpInside)
        okayButton.setTitle("ok", for: .normal)
        okayButton.setTitleColor(UIColor.blue, for: .normal)
        
        
        let cancelButton = UIButton(frame: CGRect(x: mycustomView.frame.width / 2, y: mycustomView.frame.height - 50, width: mycustomView.frame.width / 2, height: 50))
        cancelButton.backgroundColor = UIColor.white
        
        // here we are adding the button its superView
        mycustomView.addSubview(cancelButton)
        
        cancelButton.addTarget(self, action: #selector(self.cancelButtonImplementation), for:.touchUpInside)
        cancelButton.setTitle("cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.blue, for: .normal)
        
        
        
    }
    func okButtonImplementation(sender:UIButton) {
        print("pushed okay button!!!")
        if hashInput.hasText {
            postingHash = hashInput.text!
            
            postingHash = postingHash.replacingOccurrences(of: " ", with: "")
            
        }
        putLocation()
        mycustomView.isHidden = true
        mycustomView.endEditing(true)
    }
    func cancelButtonImplementation(sender:UIButton) {
        print("pushed cancel button!!!")
        mycustomView.isHidden = true
        mycustomView.endEditing(true)
    }
}

// Delegates to handle events for the location manager.
extension ViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        movedMapGetLocals()
        
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    
    
}
