//
//  DestinationManager.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class DestinationManager: ObservableObject {
    @Published var destination: CLLocation?
    @Published var destinationName: String?
    @Published var hasArrived = false
    @Published var distanceToDestination: Double = 0
    
    private let arrivalThreshold: Double = 50 // meters
    
    func setDestination(_ location: CLLocation, name: String) {
        destination = location
        destinationName = name
        hasArrived = false
    }
    
    func clearDestination() {
        destination = nil
        destinationName = nil
        hasArrived = false
        distanceToDestination = 0
    }
    
    func checkArrival(currentLocation: CLLocation) {
        guard let destination = destination, !hasArrived else { return }
        
        let distance = currentLocation.distance(from: destination)
        distanceToDestination = distance
        
        if distance <= arrivalThreshold {
            hasArrived = true
            notifyArrival()
        }
    }
    
    private func notifyArrival() {
        // Send local notification
        let content = UNMutableNotificationContent()
        content.title = "SafeTrail - 已安全到达"
        content.body = "您已安全到达\(destinationName ?? "目的地")，旅程结束。"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "arrival_notification",
            content: content,
            trigger: nil // Immediate notification
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

import UserNotifications

extension UNUserNotificationCenter {
    static func requestPermission() {
        current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}