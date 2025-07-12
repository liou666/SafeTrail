//
//  SharingService.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import Foundation
import MessageUI
import SwiftUI

class SharingService: ObservableObject {
    static let shared = SharingService()
    
    private init() {}
    
    func generateShareLink(for session: SafetySession) -> String {
        // 创建简单的文本分享链接
        return "https://maps.apple.com/?q=正在追踪位置&t=m"
    }
    
    func shareLocation(session: SafetySession, location: LocationData?) {
        let message = createShareMessage(session: session, location: location)
        
        // 如果有位置信息，直接分享当前位置的地图链接
        var shareItems: [Any] = [message]
        
        if let location = location {
            let mapURL = "https://maps.apple.com/?q=\(location.latitude),\(location.longitude)&t=m"
            shareItems.append(URL(string: mapURL)!)
        } else {
            let shareLink = generateShareLink(for: session)
            shareItems.append(URL(string: shareLink)!)
        }
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window.rootViewController?.view
                    popover.sourceRect = CGRect(x: window.frame.midX, y: window.frame.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
    
    private func createShareMessage(session: SafetySession, location: LocationData?) -> String {
        var message = "🛡️ 我正在使用SafeTrail安全出行\n\n"
        message += "开始时间: \(session.startTime.formatted(date: .abbreviated, time: .shortened))\n"
        
        if let location = location {
            message += "当前位置: \(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude))\n"
            message += "地图链接: https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)\n\n"
        }
        
        message += "点击下方链接实时查看我的位置:\n"
        
        return message
    }
    
    func sendEmergencyAlert(to contacts: [EmergencyContact], location: LocationData?, message: String = "我可能遇到危险，请联系我") {
        guard !contacts.isEmpty else { return }
        
        let emergencyMessage = createEmergencyMessage(location: location, customMessage: message)
        
        for contact in contacts where contact.isEnabled {
            sendSMS(to: contact.phoneNumber, message: emergencyMessage)
        }
    }
    
    private func createEmergencyMessage(location: LocationData?, customMessage: String) -> String {
        var message = "🚨 紧急求助 - SafeTrail\n\n"
        message += "\(customMessage)\n\n"
        message += "时间: \(Date().formatted(date: .abbreviated, time: .shortened))\n"
        
        if let location = location {
            message += "位置: \(String(format: "%.6f", location.latitude)), \(String(format: "%.6f", location.longitude))\n"
            message += "地图: https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)\n"
        }
        
        message += "\n请立即联系我或拨打紧急电话。"
        
        return message
    }
    
    private func sendSMS(to phoneNumber: String, message: String) {
        if MFMessageComposeViewController.canSendText() {
            DispatchQueue.main.async {
                let messageVC = MFMessageComposeViewController()
                messageVC.recipients = [phoneNumber]
                messageVC.body = message
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(messageVC, animated: true)
                }
            }
        } else {
            // Fallback to opening Messages app
            let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "sms:\(phoneNumber)&body=\(encodedMessage)") {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}