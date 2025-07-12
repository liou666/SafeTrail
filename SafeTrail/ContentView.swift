//
//  ContentView.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = LocationManager()
    @StateObject private var sharingService = SharingService.shared
    @StateObject private var destinationManager = DestinationManager()
    @StateObject private var routeTracker = RouteTracker()
    @Query private var activeSessions: [SafetySession]
    @Query private var emergencyContacts: [EmergencyContact]
    @State private var showingSettings = false
    @State private var showingEmergencyMode = false
    @State private var showingShareSheet = false
    @State private var showingDestinationPicker = false
    @State private var selectedTab = 0
    
    private var currentSession: SafetySession? {
        activeSessions.first { $0.isActive }
    }
    
    private var authStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "未确定"
        case .denied: return "已拒绝"
        case .restricted: return "受限制"
        case .authorizedWhenInUse: return "使用时允许"
        case .authorizedAlways: return "始终允许"
        @unknown default: return "未知"
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 安全模式标签页
            NavigationView {
                SafetyModeView()
            }
            .tabItem {
                Image(systemName: "shield.checkered")
                Text("安全模式")
            }
            .tag(0)
            
            // 地图和路线标签页
            NavigationView {
                MapAndStatsView()
            }
            .tabItem {
                Image(systemName: "map")
                Text("路线")
            }
            .tag(1)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingDestinationPicker) {
            DestinationPickerView(destinationManager: destinationManager)
        }
        .fullScreenCover(isPresented: $showingEmergencyMode) {
            EmergencyModeView(isPresented: $showingEmergencyMode)
                .environmentObject(locationManager)
                .environmentObject(sharingService)
        }
        .onAppear {
            locationManager.requestPermission()
            UNUserNotificationCenter.requestPermission()
            
            // 设置位置更新回调到路线追踪器
            locationManager.onLocationUpdate = { location in
                routeTracker.addLocation(location)
                
                // 原有的位置更新逻辑
                if let session = currentSession {
                    let locationData = LocationData(from: location)
                    locationData.session = session
                    modelContext.insert(locationData)
                    
                    if session.startLocation == nil {
                        session.startLocation = locationData
                    }
                    
                    destinationManager.checkArrival(currentLocation: location)
                    
                    do {
                        try modelContext.save()
                    } catch {
                        print("❌ Failed to save location: \(error)")
                    }
                }
            }
        }
    }
    
    private func startSafetyMode() {
        print("🚀 Starting safety mode...")
        print("📍 Current auth status: \(locationManager.authorizationStatus)")
        
        // Create session first
        let session = SafetySession()
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            print("✅ Session created and saved")
        } catch {
            print("❌ Failed to save session: \(error)")
            return
        }
        
        // Check permissions
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("🔐 Requesting location permission...")
            locationManager.requestAlwaysPermission()
            // Wait for permission response and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.locationManager.authorizationStatus == .authorizedWhenInUse || 
                   self.locationManager.authorizationStatus == .authorizedAlways {
                    self.startLocationTracking(for: session)
                }
            }
            
        case .denied, .restricted:
            print("❌ Location permission denied")
            // Show alert to user
            locationManager.errorMessage = "需要位置权限才能开启安全模式，请在设置中允许位置访问"
            
        case .authorizedWhenInUse:
            print("📱 Permission: When in use")
            startLocationTracking(for: session)
            
        case .authorizedAlways:
            print("🌍 Permission: Always")
            startLocationTracking(for: session)
            
        @unknown default:
            print("❓ Unknown permission status")
            locationManager.requestAlwaysPermission()
        }
    }
    
    private func startLocationTracking(for session: SafetySession) {
        print("🎯 Starting location tracking...")
        
        locationManager.startTracking()
        // 同时启动路线追踪
        routeTracker.startTracking()
        
        // locationManager.onLocationUpdate 已在 onAppear 中设置
    }
    
    private func endSafetyMode() {
        guard let session = currentSession else { return }
        
        session.isActive = false
        session.endTime = Date()
        
        if let location = locationManager.location {
            let endLocationData = LocationData(from: location)
            endLocationData.session = session
            session.endLocation = endLocationData
            modelContext.insert(endLocationData)
        }
        
        // 如果路线追踪没有独立运行，也停止它
        if !routeTracker.isTracking {
            locationManager.stopTracking()
        }
        
        try? modelContext.save()
    }
    
    private func copyShareLink(_ token: String) {
        if let location = locationManager.location {
            let mapURL = "https://maps.apple.com/?q=\(location.coordinate.latitude),\(location.coordinate.longitude)&t=m"
            UIPasteboard.general.string = mapURL
        } else {
            let link = "SafeTrail正在守护中，当前位置：等待GPS定位..."
            UIPasteboard.general.string = link
        }
    }
    
    private func getDisplayURL(for token: String) -> String {
        if let location = locationManager.location {
            return "maps.apple.com (当前位置)"
        } else {
            return "等待定位中..."
        }
    }
    
    private func triggerEmergencyMode() {
        showingEmergencyMode = true
    }
    
    // 路线追踪相关方法
    private func startRouteTracking() {
        print("🗺️ Starting route tracking")
        routeTracker.startTracking()
        locationManager.startTracking()
    }
    
    private func stopRouteTracking() {
        print("🗺️ Stopping route tracking")
        routeTracker.stopTracking()
        // 如果没有安全会话在进行，也停止位置追踪
        if currentSession == nil {
            locationManager.stopTracking()
        }
    }
    
    private func clearRoute() {
        print("🗺️ Clearing route")
        routeTracker.routePoints.removeAll()
        routeTracker.totalDistance = 0.0
        routeTracker.maxSpeed = 0.0
        routeTracker.averageSpeed = 0.0
    }
}


// 安全模式视图
extension ContentView {
    private func SafetyModeView() -> some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 60))
                    .foregroundColor(.mint)
                
                Text("SafeTrail")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("您的安全小精灵")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Main Safety Button
            VStack(spacing: 20) {
                if let session = currentSession {
                    // Active safety mode
                    VStack(spacing: 15) {
                        Text("🛡️ 您正在被守护中")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.mint)
                        
                        Text("开始时间: \(session.startTime.formatted(date: .omitted, time: .shortened))")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let location = locationManager.location {
                            Text("当前位置: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Share link section
                        VStack(spacing: 10) {
                            Text("分享链接:")
                                .font(.headline)
                            
                            HStack {
                                Text("\(getDisplayURL(for: session.shareToken))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .lineLimit(1)
                                
                                Button("复制") {
                                    copyShareLink(session.shareToken)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("分享") {
                                    sharingService.shareLocation(
                                        session: session,
                                        location: locationManager.location.map { LocationData(from: $0) }
                                    )
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        // Destination section
                        VStack(spacing: 10) {
                            if let destinationName = destinationManager.destinationName {
                                if destinationManager.hasArrived {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("已安全到达 \(destinationName)")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    VStack(spacing: 5) {
                                        Text("目的地: \(destinationName)")
                                            .font(.headline)
                                        Text("距离: \(Int(destinationManager.distanceToDestination))米")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                Button("设置目的地") {
                                    showingDestinationPicker = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        Button("结束安全模式") {
                            endSafetyMode()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.red)
                    }
                } else {
                    // Inactive state
                    VStack(spacing: 20) {
                        // Location permission status
                        if locationManager.authorizationStatus != .authorizedWhenInUse && 
                           locationManager.authorizationStatus != .authorizedAlways {
                            LocationPermissionStatusView(locationManager: locationManager)
                        }
                        
                        Button(action: startSafetyMode) {
                            VStack(spacing: 8) {
                                Image(systemName: "location.circle")
                                    .font(.system(size: 40))
                                Text("开启安全模式")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.mint, .cyan]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .shadow(color: .mint.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentSession != nil)
                        .disabled(locationManager.authorizationStatus == .denied || 
                                 locationManager.authorizationStatus == .restricted)
                        .opacity((locationManager.authorizationStatus == .denied || 
                                 locationManager.authorizationStatus == .restricted) ? 0.5 : 1.0)
                        
                        Text("点击开始位置共享和安全记录")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Debug info (只在开发时显示)
                        #if DEBUG
                        VStack(spacing: 4) {
                            Text("权限状态: \(authStatusText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("追踪状态: \(locationManager.isTracking ? "运行中" : "已停止")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let location = locationManager.location {
                                Text("位置: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("位置: 未获取")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        #endif
                    }
                }
            }
            
            Spacer()
            
            // Emergency button (hidden)
            Button(action: {
                showingEmergencyMode = true
            }) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 50)
            }
            .onLongPressGesture(minimumDuration: 2.0) {
                triggerEmergencyMode()
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("设置") {
                    showingSettings = true
                }
            }
        }
        .alert("Location Error", isPresented: .constant(locationManager.errorMessage != nil)) {
            Button("OK") {
                locationManager.errorMessage = nil
            }
        } message: {
            Text(locationManager.errorMessage ?? "")
        }
    }
    
    // 地图和统计视图
    private func MapAndStatsView() -> some View {
        VStack(spacing: 0) {
            // 地图视图
            MapView(locationManager: locationManager, routeTracker: routeTracker)
                .frame(maxHeight: .infinity)
            
            // 统计信息底部面板
            VStack(spacing: 16) {
                // 控制按钮
                HStack(spacing: 20) {
                    if routeTracker.isTracking {
                        Button("停止记录") {
                            stopRouteTracking()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button("开始记录") {
                            startRouteTracking()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.mint)
                    }
                    
                    Button("清除路线") {
                        clearRoute()
                    }
                    .buttonStyle(.bordered)
                }
                
                // 统计信息
                HStack(spacing: 0) {
                    StatCard(
                        title: "距离",
                        value: "\(routeTracker.formattedDistance)km",
                        icon: "road.lanes"
                    )
                    
                    StatCard(
                        title: "最大速度",
                        value: "\(routeTracker.formattedMaxSpeed)km/h",
                        icon: "speedometer"
                    )
                    
                    StatCard(
                        title: "用时",
                        value: routeTracker.elapsedTime,
                        icon: "clock"
                    )
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(.container, edges: .bottom)
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("路线追踪")
    }
}

// 统计卡片视图
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.mint)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmergencyModeView: View {
    @Binding var isPresented: Bool
    @State private var showFakeUI = false
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var sharingService: SharingService
    @Query private var emergencyContacts: [EmergencyContact]
    
    var body: some View {
        ZStack {
            if showFakeUI {
                // Fake calendar interface
                VStack {
                    Text("Calendar")
                        .font(.largeTitle)
                        .padding()
                    
                    Text("今天, \(Date().formatted(date: .complete, time: .omitted))")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                    
                    Text("No events today")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .onTapGesture(count: 3) {
                    isPresented = false
                }
            } else {
                // Emergency alert
                VStack(spacing: 30) {
                    Text("🚨 紧急求助已触发")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("正在发送您的位置信息给紧急联系人...")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Button("隐藏界面") {
                        showFakeUI = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .onAppear {
                    sendEmergencyAlert()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showFakeUI = true
                    }
                }
            }
        }
        .background(Color.black)
    }
    
    private func sendEmergencyAlert() {
        guard !emergencyContacts.isEmpty else {
            print("No emergency contacts configured")
            return
        }
        
        let currentLocation = locationManager.location.map { LocationData(from: $0) }
        sharingService.sendEmergencyAlert(
            to: emergencyContacts.filter { $0.isEnabled },
            location: currentLocation,
            message: "我可能遇到危险，请联系我"
        )
        
        print("Emergency alert sent to \(emergencyContacts.filter { $0.isEnabled }.count) contacts")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [EmergencyContact.self, SafetySession.self, LocationData.self], inMemory: true)
}
