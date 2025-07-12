//
//  Models.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class EmergencyContact {
    var id: UUID
    var name: String
    var phoneNumber: String
    var isEnabled: Bool
    var createdAt: Date
    
    init(name: String, phoneNumber: String) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.isEnabled = true
        self.createdAt = Date()
    }
}

@Model
final class SafetySession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var startLocation: LocationData?
    var endLocation: LocationData?
    var isActive: Bool
    var shareToken: String
    var destinationName: String?
    var destinationLatitude: Double?
    var destinationLongitude: Double?
    
    init() {
        self.id = UUID()
        self.startTime = Date()
        self.isActive = true
        self.shareToken = UUID().uuidString
    }
}

@Model
final class LocationData {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var accuracy: Double
    var session: SafetySession?
    
    init(latitude: Double, longitude: Double, accuracy: Double = 0.0) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.timestamp = Date()
    }
    
    convenience init(from location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy
        )
    }
}
