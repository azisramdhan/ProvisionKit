//
//  DeviceDetailView.swift
//  ProvisionKit
//
//  Created by Azis Ramdhan on 25/10/25.
//

import SwiftUI

struct DeviceDetailView: View {
    let profile: ProfileInfo
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme  // ✅ Use environment for dark mode detection

    var filteredDevices: [String] {
        if searchText.isEmpty {
            return profile.devices
        } else {
            return profile.devices.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
            .padding(8)
            .background(
                colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.gray.opacity(0.1)
            )
            .cornerRadius(6)

            Divider()

            if filteredDevices.isEmpty {
                Text("No matching devices.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredDevices, id: \.self) { device in
                            Text(device)
                                .font(.system(.body, design: .monospaced))
                                .padding(.vertical, 2)
                        }
                    }
                    .padding()
                }
            }

            Spacer()
        }
        .padding()
    }
}
