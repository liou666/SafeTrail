//
//  SettingsView.swift
//  SafeTrail
//
//  Created by 刘新奇 on 2025/7/12.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var emergencyContacts: [EmergencyContact]
    @State private var showingAddContact = false
    @State private var emergencyMessage = "我可能遇到危险，请联系我"
    @State private var enableBackgroundLocation = true
    @State private var enableEmergencySharing = true
    
    var body: some View {
        NavigationView {
            List {
                Section("紧急联系人") {
                    ForEach(emergencyContacts) { contact in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .font(.headline)
                                Text(contact.phoneNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { contact.isEnabled },
                                set: { newValue in
                                    contact.isEnabled = newValue
                                    try? modelContext.save()
                                }
                            ))
                        }
                    }
                    .onDelete(perform: deleteContacts)
                    
                    Button("添加联系人") {
                        showingAddContact = true
                    }
                    .foregroundColor(.mint)
                }
                
                Section("紧急求助设置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("紧急求助消息")
                            .font(.headline)
                        
                        TextEditor(text: $emergencyMessage)
                            .frame(height: 80)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("启用后台位置追踪", isOn: $enableBackgroundLocation)
                    Toggle("启用紧急分享", isOn: $enableEmergencySharing)
                }
                
                Section("应用信息") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("使用条款")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("危险情况下的使用") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("紧急求助方式:")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.mint)
                            Text("长按主界面底部空白区域2秒")
                        }
                        
                        HStack {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(.mint)
                            Text("求助后会自动切换到伪装界面")
                        }
                        
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.mint)
                            Text("在伪装界面三击屏幕退出")
                        }
                    }
                    .padding(.vertical, 4)
                    .font(.caption)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
            }
        }
    }
    
    private func deleteContacts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(emergencyContacts[index])
            }
            try? modelContext.save()
        }
    }
}

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var phoneNumber = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("联系人信息") {
                    TextField("姓名", text: $name)
                    TextField("手机号码", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Text("该联系人将在您触发紧急求助时收到您的位置信息和求助消息。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加紧急联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveContact()
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
        }
    }
    
    private func saveContact() {
        let contact = EmergencyContact(name: name, phoneNumber: phoneNumber)
        modelContext.insert(contact)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [EmergencyContact.self], inMemory: true)
}