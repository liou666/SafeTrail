//
//  MapView.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var routeTracker: RouteTracker
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.6725, longitude: 104.0635), // 成都
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var trackingMode: MapUserTrackingMode = .none
    @State private var isUserInteracting = false
    @State private var lastUserInteraction = Date()
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $trackingMode,
                annotationItems: routeTracker.routePoints) { point in
                MapPin(coordinate: point.coordinate, tint: .mint)
            }
            .overlay(
                // 路线叠加层
                RouteOverlay(routePoints: routeTracker.routePoints)
            )
            .onReceive(locationManager.$location) { location in
                // 只有在跟踪模式开启且用户没有手动操作地图时才自动更新位置
                if let location = location,
                   trackingMode != .none,
                   !isUserInteracting,
                   Date().timeIntervalSince(lastUserInteraction) > 3.0 {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        region.center = location.coordinate
                    }
                }
            }
            .gesture(
                // 检测用户手势交互
                DragGesture()
                    .onChanged { _ in
                        isUserInteracting = true
                        lastUserInteraction = Date()
                        // 用户开始拖拽时自动关闭跟踪模式
                        if trackingMode != .none {
                            trackingMode = .none
                        }
                    }
                    .onEnded { _ in
                        isUserInteracting = false
                    }
                    .simultaneously(with:
                        MagnificationGesture()
                            .onChanged { _ in
                                isUserInteracting = true
                                lastUserInteraction = Date()
                                // 用户开始缩放时自动关闭跟踪模式
                                if trackingMode != .none {
                                    trackingMode = .none
                                }
                            }
                            .onEnded { _ in
                                isUserInteracting = false
                            }
                    )
            )
            
            // 顶部控制栏
            VStack {
                HStack {
                    // 追踪模式切换按钮
                    Button(action: {
                        switch trackingMode {
                        case .none:
                            trackingMode = .follow
                            // 重新开始跟踪时，立即移动到用户位置
                            if let location = locationManager.location {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    region.center = location.coordinate
                                }
                            }
                        case .follow:
                            trackingMode = .followWithHeading
                        case .followWithHeading:
                            trackingMode = .none
                        @unknown default:
                            trackingMode = .follow
                        }
                        // 重置交互状态
                        isUserInteracting = false
                        lastUserInteraction = Date().addingTimeInterval(-5)
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: trackingModeIcon)
                                .font(.title2)
                            if trackingMode != .none {
                                Circle()
                                    .fill(.mint)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .foregroundColor(trackingMode != .none ? .mint : .white)
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                    }
                    
                    Spacer()
                    
                    // 控制按钮组
                    VStack(spacing: 8) {
                        // 回到我的位置按钮
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(.mint)
                                .padding(6)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                        }
                        
                        // 缩放控制
                        Button(action: zoomIn) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                        }
                        
                        Button(action: zoomOut) {
                            Image(systemName: "minus")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    private var trackingModeIcon: String {
        switch trackingMode {
        case .none:
            return "location"
        case .follow:
            return "location.fill"
        case .followWithHeading:
            return "location.north.line.fill"
        @unknown default:
            return "location"
        }
    }
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            region.span.latitudeDelta = max(region.span.latitudeDelta / 2, 0.001)
            region.span.longitudeDelta = max(region.span.longitudeDelta / 2, 0.001)
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 1.0)
            region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 1.0)
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation(.easeInOut(duration: 1.0)) {
                region.center = location.coordinate
                // 适当缩放到合适的级别
                region.span.latitudeDelta = 0.01
                region.span.longitudeDelta = 0.01
            }
        }
    }
}

// 路线叠加视图
struct RouteOverlay: View {
    let routePoints: [RoutePoint]
    
    var body: some View {
        if routePoints.count > 1 {
            RoutePolyline(routePoints: routePoints)
        }
    }
}

// 路线折线图
struct RoutePolyline: UIViewRepresentable {
    let routePoints: [RoutePoint]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = false
        mapView.backgroundColor = .clear
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 清除旧的路线
        mapView.removeOverlays(mapView.overlays)
        
        if routePoints.count > 1 {
            let coordinates = routePoints.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemMint
                renderer.lineWidth = 4.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// 路线点数据模型
struct RoutePoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let speed: CLLocationSpeed
    let altitude: CLLocationDistance
}

// 路线追踪器
class RouteTracker: ObservableObject {
    @Published var routePoints: [RoutePoint] = []
    @Published var totalDistance: Double = 0.0
    @Published var maxSpeed: Double = 0.0
    @Published var averageSpeed: Double = 0.0
    @Published var isTracking: Bool = false
    
    private var startTime: Date?
    
    func startTracking() {
        isTracking = true
        startTime = Date()
        routePoints.removeAll()
        totalDistance = 0.0
        maxSpeed = 0.0
        print("🗺️ Started route tracking")
    }
    
    func stopTracking() {
        isTracking = false
        startTime = nil
        print("🗺️ Stopped route tracking")
    }
    
    func addLocation(_ location: CLLocation) {
        guard isTracking else { return }
        
        let newPoint = RoutePoint(
            coordinate: location.coordinate,
            timestamp: location.timestamp,
            speed: max(0, location.speed), // 确保速度不为负
            altitude: location.altitude
        )
        
        // 添加新点
        routePoints.append(newPoint)
        
        // 计算距离（如果有前一个点）
        if routePoints.count > 1 {
            let previousPoint = routePoints[routePoints.count - 2]
            let previousLocation = CLLocation(
                latitude: previousPoint.coordinate.latitude,
                longitude: previousPoint.coordinate.longitude
            )
            let distance = location.distance(from: previousLocation)
            totalDistance += distance
        }
        
        // 更新最大速度
        let speedKmh = location.speed * 3.6 // 转换为公里/小时
        if speedKmh > maxSpeed {
            maxSpeed = speedKmh
        }
        
        // 计算平均速度
        if let startTime = startTime {
            let elapsedTime = Date().timeIntervalSince(startTime) / 3600.0 // 转换为小时
            if elapsedTime > 0 {
                averageSpeed = (totalDistance / 1000.0) / elapsedTime // 公里/小时
            }
        }
        
        print("📍 Added route point: distance=\(String(format: "%.2f", totalDistance/1000))km, speed=\(String(format: "%.1f", speedKmh))km/h")
    }
    
    var totalDistanceKm: Double {
        totalDistance / 1000.0
    }
    
    var formattedDistance: String {
        String(format: "%.2f", totalDistanceKm)
    }
    
    var formattedMaxSpeed: String {
        String(format: "%.1f", maxSpeed)
    }
    
    var formattedAverageSpeed: String {
        String(format: "%.1f", averageSpeed)
    }
    
    var elapsedTime: String {
        guard let startTime = startTime else { return "00:00:00" }
        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) % 3600 / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    MapView(locationManager: LocationManager(), routeTracker: RouteTracker())
}