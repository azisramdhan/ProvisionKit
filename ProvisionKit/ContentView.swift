import SwiftUI

// MARK: - Views

struct ContentView: View {
    @State private var profiles: [ProfileInfo] = []
    @State private var selectedProfile: ProfileInfo?
    @State private var folderURL: URL?

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

#Preview {
    ContentView()
}
