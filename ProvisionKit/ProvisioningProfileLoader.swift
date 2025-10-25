//
//  ProvisioningProfileLoader.swift
//  ProvisionKit
//
//  Created by Azis Ramdhan on 25/10/25.
//

import Foundation
import AppKit

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
