//
//  LocationPermissionGuideView.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import SwiftUI
import CoreLocation

struct LocationPermissionGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    @State private var currentStep = 0
    
    let steps = [
        PermissionStep(
            icon: "location.circle",
            title: "位置权限",
            description: "SafeTrail需要访问您的位置来提供安全保护服务",
            color: .mint
        ),
        PermissionStep(
            icon: "shield.checkered",
            title: "安全保护",
            description: "我们会记录您的行程路线，确保家人朋友能了解您的安全状况",
            color: .cyan
        ),
        PermissionStep(
            icon: "bell.badge",
            title: "通知权限",
            description: "当您安全到达目的地时，我们会发送通知提醒",
            color: .green
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.mint : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top)
                
                Spacer()
                
                // Current step content
                VStack(spacing: 24) {
                    Image(systemName: steps[currentStep].icon)
                        .font(.system(size: 80))
                        .foregroundColor(steps[currentStep].color)
                    
                    VStack(spacing: 12) {
                        Text(steps[currentStep].title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(steps[currentStep].description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if currentStep < steps.count - 1 {
                        Button("下一步") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.mint)
                    } else {
                        // Final step - request permissions
                        VStack(spacing: 12) {
                            Button("开启位置权限") {
                                print("🔥 开启位置权限 button pressed!")
                                requestLocationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(.mint)
                            
                            if locationManager.authorizationStatus == .denied {
                                Button("前往设置") {
                                    openSettings()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
                    }
                    
                    Button("跳过") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .onChange(of: locationManager.authorizationStatus) { _, status in
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    dismiss()
                }
            }
        }
    }
    
    private func requestLocationPermission() {
        print("🔐 LocationPermissionGuideView: Requesting location permission...")
        print("📍 Current auth status: \(locationManager.authorizationStatus)")
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("🔐 Status is notDetermined, requesting permission...")
            locationManager.requestAlwaysPermission()
        case .denied:
            print("❌ Permission denied, opening settings...")
            openSettings()
        case .restricted:
            print("⚠️ Permission restricted")
            break
        case .authorizedWhenInUse:
            print("✅ Permission: When in use - requesting always")
            locationManager.requestAlwaysPermission()
        case .authorizedAlways:
            print("✅ Permission: Always - dismissing")
            dismiss()
        @unknown default:
            print("❓ Unknown permission status")
            locationManager.requestAlwaysPermission()
        }
    }
    
    private func openSettings() {
        // 优先尝试打开定位服务设置页面
        if let url = URL(string: "App-prefs:Privacy&path=LOCATION") {
            UIApplication.shared.open(url) { success in
                if !success {
                    // 如果无法打开定位设置，则打开应用设置页面
                    if let appSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettingsUrl)
                    }
                }
            }
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
}

struct PermissionStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct LocationPermissionStatusView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var showingGuide = false
    
    var body: some View {
        VStack(spacing: 16) {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                LocationStatusCard(
                    icon: "location.slash",
                    title: "需要位置权限",
                    description: "点击下方按钮开启位置服务",
                    color: .orange,
                    action: {
                        print("🔥 开启引导 button pressed!")
                        showingGuide = true
                    },
                    actionText: "开启引导"
                )
                
            case .denied:
                VStack(spacing: 12) {
                    LocationStatusCard(
                        icon: "location.slash.fill",
                        title: "位置权限被拒绝",
                        description: "点击下方按钮前往系统设置开启位置权限",
                        color: .red,
                        action: {
                            print("🔥 打开位置设置 button pressed!")
                            openLocationSettings()
                        },
                        actionText: "打开位置设置"
                    )
                    
                    // 操作指导
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📱 设置步骤：")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("1.")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("找到「SafeTrail」应用")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("2.")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("点击「位置」选项")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("3.")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("选择「使用App时」或「始终」")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.05))
                    )
                }
                
            case .restricted:
                LocationStatusCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "位置服务受限",
                    description: "您的设备限制了位置服务的使用",
                    color: .orange,
                    action: nil,
                    actionText: nil
                )
                
            case .authorizedWhenInUse:
                LocationStatusCard(
                    icon: "location.circle.fill",
                    title: "位置权限：使用时允许",
                    description: "建议开启「始终允许」以获得更好的安全保护",
                    color: .yellow,
                    action: {
                        print("🔥 升级权限 button pressed!")
                        locationManager.requestAlwaysPermission()
                    },
                    actionText: "升级权限"
                )
                
            case .authorizedAlways:
                LocationStatusCard(
                    icon: "checkmark.circle.fill",
                    title: "位置权限已开启",
                    description: "SafeTrail已准备好为您提供安全保护",
                    color: .green,
                    action: nil,
                    actionText: nil
                )
                
            @unknown default:
                EmptyView()
            }
        }
        .sheet(isPresented: $showingGuide) {
            LocationPermissionGuideView(locationManager: locationManager)
        }
    }
    
    private func openLocationSettings() {
        print("🔧 openLocationSettings called in LocationPermissionStatusView")
        // 优先尝试打开定位服务设置页面
        if let url = URL(string: "App-prefs:Privacy&path=LOCATION") {
            print("🔧 Trying to open location settings: \(url)")
            UIApplication.shared.open(url) { success in
                print("🔧 Location settings open success: \(success)")
                if !success {
                    // 如果无法打开定位设置，则打开应用设置页面
                    if let appSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        print("🔧 Falling back to app settings: \(appSettingsUrl)")
                        UIApplication.shared.open(appSettingsUrl)
                    }
                }
            }
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            print("🔧 Opening app settings: \(url)")
            UIApplication.shared.open(url)
        }
    }
}

struct LocationStatusCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: (() -> Void)?
    let actionText: String?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let action = action, let actionText = actionText {
                Button(actionText) {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(color)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    LocationPermissionGuideView(locationManager: LocationManager())
}