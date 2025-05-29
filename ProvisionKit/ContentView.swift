import SwiftUI
import Foundation
import AppKit

// MARK: - Model

struct ProfileInfo: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let uuid: String
    let teamIdentifier: String
    let creationDate: Date
    let expirationDate: Date
    let path: URL
    let devices: [String]
}

// MARK: - Loader

class ProvisioningProfileLoader {
    static func askForDirectoryAccess() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select Provisioning Profiles Folder"
        panel.message = "Choose the folder containing your .mobileprovision files"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/UserData/Provisioning Profiles")

        return panel.runModal() == .OK ? panel.url : nil
    }

    static func loadProfiles(from directory: URL) -> [ProfileInfo] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }

        let profiles = contents.filter { $0.pathExtension == "mobileprovision" }
        return profiles.compactMap { parseProfile(from: $0) }
    }

    static func parseProfile(from fileURL: URL) -> ProfileInfo? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        let xmlStart = "<?xml".data(using: .utf8)!
        let plistEnd = "</plist>".data(using: .utf8)!

        guard let startRange = data.range(of: xmlStart),
              let endRange = data.range(of: plistEnd, options: [], in: startRange.lowerBound..<data.endIndex) else {
            return nil
        }

        let plistData = data[startRange.lowerBound..<endRange.upperBound]

        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            return nil
        }

        return ProfileInfo(
            name: dict["Name"] as? String ?? "Unknown",
            uuid: dict["UUID"] as? String ?? "Unknown",
            teamIdentifier: (dict["TeamIdentifier"] as? [String])?.first ?? "Unknown",
            creationDate: dict["CreationDate"] as? Date ?? .distantPast,
            expirationDate: dict["ExpirationDate"] as? Date ?? .distantFuture,
            path: fileURL,
            devices: dict["ProvisionedDevices"] as? [String] ?? []
        )
    }
}

// MARK: - Views

struct ContentView: View {
    @State private var profiles: [ProfileInfo] = []
    @State private var selectedProfile: ProfileInfo?
    @State private var folderURL: URL? = nil

    var body: some View {
        VStack {
            if profiles.isEmpty {
                VStack(spacing: 20) {
                    Text("No provisioning profiles loaded.")
                        .foregroundColor(.secondary)
                    Button("Select Provisioning Profiles Folder") {
                        pickFolder()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    List {
                        ForEach(profiles) { profile in
                            VStack(alignment: .leading) {
                                Text(profile.name).font(.headline)
                                Text("UUID: \(profile.uuid)").font(.caption)
                                Text("Team: \(profile.teamIdentifier)").font(.caption)
                                Text("Expires: \(profile.expirationDate.formatted())").font(.caption2)
                                Text("Devices: \(profile.devices.count)").font(.caption2)
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                profile == selectedProfile
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                            )
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedProfile = profile
                            }
                        }
                    }
                    .frame(minWidth: 300)
                    .listStyle(SidebarListStyle())

                    Divider()

                    if let profile = selectedProfile {
                        DeviceDetailView(profile: profile)
                            .frame(minWidth: 400)
                    } else {
                        Text("Select a profile to see devices")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 700, minHeight: 400)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            pickFolder()
                        } label: {
                            Label("Select Folder", systemImage: "folder")
                        }
                        .help("Select Provisioning Profiles Folder")
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    func pickFolder() {
        if let url = ProvisioningProfileLoader.askForDirectoryAccess() {
            folderURL = url
            profiles = ProvisioningProfileLoader.loadProfiles(from: url)
            selectedProfile = profiles.first
        } else {
            profiles = []
            selectedProfile = nil
        }
    }
}

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

#Preview {
    ContentView()
}
