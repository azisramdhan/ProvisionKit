//
//  ProfileInfo.swift
//  ProvisionKit
//
//  Created by Azis Ramdhan on 25/10/25.
//

import Foundation

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
