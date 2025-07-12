//
//  LocationManager.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var errorMessage: String?
    
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestPermission() {
        print("🔐 Requesting when-in-use permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermission() {
        print("🔐 Requesting always permission...")
        // For iOS 13.4+, we need to request when-in-use first, then always
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func startTracking() {
        print("🎯 StartTracking called with auth: \(authorizationStatus)")
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ No location permission")
            errorMessage = "需要位置权限才能开启追踪"
            return
        }
        
        print("✅ Starting location updates...")
        locationManager.startUpdatingLocation()
        
        if authorizationStatus == .authorizedAlways {
            print("🌍 Setting up background location updates")
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
        
        isTracking = true
        errorMessage = nil
        print("✅ Location tracking started")
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        isTracking = false
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let newLocation = locations.last else { return }
            print("📍 Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
            location = newLocation
            onLocationUpdate?(newLocation)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            print("🔐 Authorization changed to: \(status) (rawValue: \(status.rawValue))")
            
            switch status {
            case .notDetermined:
                print("🔐 Status: Not Determined")
            case .denied:
                print("🔐 Status: Denied")
            case .restricted:
                print("🔐 Status: Restricted")
            case .authorizedWhenInUse:
                print("🔐 Status: Authorized When In Use")
            case .authorizedAlways:
                print("🔐 Status: Authorized Always")
            @unknown default:
                print("🔐 Status: Unknown (\(status.rawValue))")
            }
            
            authorizationStatus = status
            
            // Auto-start tracking if we have permission and were waiting for it
            if (status == .authorizedWhenInUse || status == .authorizedAlways) && !isTracking {
                print("✅ Got permission, checking if we need to start tracking...")
            }
        }
    }
}