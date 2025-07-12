//
//  DestinationPickerView.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import SwiftUI
import CoreLocation
import MapKit

struct DestinationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var destinationManager: DestinationManager
    @State private var destinationName = ""
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: CLLocation?
    @State private var showingCustomLocation = false
    
    private let commonDestinations = [
        ("🏠 家", "家"),
        ("🏢 公司", "公司"),
        ("🏫 学校", "学校"),
        ("🚇 地铁站", "地铁站"),
        ("🛒 超市", "超市")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section("常用目的地") {
                    ForEach(commonDestinations, id: \.0) { icon, name in
                        Button(action: {
                            destinationName = name
                            showingCustomLocation = true
                        }) {
                            HStack {
                                Text(icon)
                                Text(name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("搜索地点") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("输入地点名称或地址", text: $searchText)
                            .onSubmit {
                                searchForLocation()
                            }
                    }
                    
                    ForEach(searchResults, id: \.self) { item in
                        Button(action: {
                            selectSearchResult(item)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "未知地点")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let address = item.placemark.title {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section("自定义位置") {
                    Button("手动输入坐标") {
                        showingCustomLocation = true
                    }
                }
            }
            .navigationTitle("选择目的地")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomLocation) {
                CustomLocationView(
                    destinationName: $destinationName,
                    selectedLocation: $selectedLocation,
                    onSave: { name, location in
                        destinationManager.setDestination(location, name: name)
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response {
                    self.searchResults = response.mapItems
                } else {
                    self.searchResults = []
                }
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        let location = CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )
        
        destinationManager.setDestination(location, name: item.name ?? "选定位置")
        dismiss()
    }
}

struct CustomLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var destinationName: String
    @Binding var selectedLocation: CLLocation?
    @State private var latitude = ""
    @State private var longitude = ""
    
    let onSave: (String, CLLocation) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("目的地信息") {
                    TextField("目的地名称", text: $destinationName)
                }
                
                Section("位置坐标") {
                    TextField("纬度", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("经度", text: $longitude)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Text("您可以从地图应用复制坐标信息，或使用当前位置作为目的地。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("自定义目的地")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCustomLocation()
                    }
                    .disabled(destinationName.isEmpty || latitude.isEmpty || longitude.isEmpty)
                }
            }
        }
    }
    
    private func saveCustomLocation() {
        guard let lat = Double(latitude),
              let lng = Double(longitude),
              !destinationName.isEmpty else { return }
        
        let location = CLLocation(latitude: lat, longitude: lng)
        onSave(destinationName, location)
        dismiss()
    }
}

#Preview {
    DestinationPickerView(destinationManager: DestinationManager())
}