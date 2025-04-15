//
//  SceneDelegate.swift
//  Example
//
//  Created by Patrick Kladek on 16.05.24.
//

import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import BeMap
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var viewController: NavigationViewController!
    var route: Route!
    
    let startButton = UIButton()
    let waypoints = [
        CLLocation(latitude: 10.774363, longitude: 106.688320),
        CLLocation(latitude: 10.765873, longitude: 106.667630) // Nearby location
    ].map { Waypoint(location: $0) }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
		
        self.window = UIWindow(windowScene: windowScene)
        
        // Initialize NavigationViewController with custom style URL
        let customStyleURL = URL(string: "https://bemap-maptiles-qa.veep.me/styles/basemap/style.json")!
        self.viewController = NavigationViewController(dayStyle: DayStyle(mapStyleURL: customStyleURL), nightStyle: NightStyle(mapStyleURL: customStyleURL))
        self.viewController.mapView.tracksUserCourse = false
        self.viewController.mapView.showsUserLocation = true
        self.viewController.mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 10.8231, longitude: 106.6297) // HCMC coordinates
        self.viewController.delegate = self
        
        self.window?.rootViewController = self.viewController
        self.window?.makeKeyAndVisible()
        
        self.viewController.mapView.zoomLevel = 13 // Increase zoom level for better city view

        let positionCameraRandomlyButton = UIButton()
        positionCameraRandomlyButton.translatesAutoresizingMaskIntoConstraints = false
        positionCameraRandomlyButton.setImage(UIImage(systemName: "globe"), for: .normal)
        positionCameraRandomlyButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        positionCameraRandomlyButton.backgroundColor = .white
        positionCameraRandomlyButton.layer.cornerRadius = 8
        self.viewController.view.addSubview(positionCameraRandomlyButton)
        NSLayoutConstraint.activate([
            positionCameraRandomlyButton.trailingAnchor.constraint(equalTo: self.viewController.view.layoutMarginsGuide.trailingAnchor),
            positionCameraRandomlyButton.centerYAnchor.constraint(equalTo: self.viewController.view.centerYAnchor),
            positionCameraRandomlyButton.widthAnchor.constraint(equalTo: positionCameraRandomlyButton.heightAnchor),
            positionCameraRandomlyButton.widthAnchor.constraint(equalToConstant: 44)
        ])
        
        self.startButton.translatesAutoresizingMaskIntoConstraints = false
        self.startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        self.startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        self.startButton.backgroundColor = .white
        self.startButton.layer.cornerRadius = 8
        self.viewController.view.addSubview(self.startButton)
        NSLayoutConstraint.activate([
            self.startButton.trailingAnchor.constraint(equalTo: self.viewController.view.layoutMarginsGuide.trailingAnchor),
            positionCameraRandomlyButton.bottomAnchor.constraint(equalTo: self.startButton.topAnchor, constant: -12),
            self.startButton.widthAnchor.constraint(equalTo: self.startButton.heightAnchor),
            self.startButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
}

extension SceneDelegate: NavigationViewControllerDelegate {
    func navigationViewControllerDidFinishRouting(_ navigationViewController: NavigationViewController) {
        navigationViewController.endNavigation()
    }
}

// MARK: - Private

private extension SceneDelegate {
    func startNavigation(for waypoints: [Waypoint]) {
        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        options.shapeFormat = .polyline6
        options.distanceMeasurementSystem = .metric
        options.attributeOptions = []
        
        Directions.shared.calculate(options) { _, routes, error in
            print("Error Directions: \(String(describing: error))")
            guard let route = routes?.first else { return }
            
            self.route = route
            
            let simulatedLocationManager = SimulatedLocationManager(route: route)
            simulatedLocationManager.speedMultiplier = 2
            
            self.viewController.startNavigation(with: route, animated: true, locationManager: simulatedLocationManager)
        }
    }
    
    @objc
    func cameraButtonTapped() {
        guard let waypoint = self.waypoints.randomElement() else { return }

        let distance = CLLocationDistance.random(in: 10 ... 100_000)
        self.viewController.mapView.camera = .init(lookingAtCenter: waypoint.coordinate,
                                                   acrossDistance: distance,
                                                   pitch: 0,
                                                   heading: 0)
    }
    
    @objc
    func startButtonTapped() {
        if self.viewController.route == nil {
            self.startNavigation(for: Array(self.waypoints[0 ... 1]))
            self.startButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        } else {
            self.viewController.endNavigation()
            self.startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
}
