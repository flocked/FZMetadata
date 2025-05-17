//
//  MetadataQuery+SearchScope.swift
//
//
//  Created by Florian Zand on 10.03.23.
//

import Foundation

public extension MetadataQuery {
    /// Search scopes for where the metadata query searches files.
    enum SearchScope: String, Hashable {
        #if os(macOS)
        /// Search the user’s home directory.
        case home
        
        /// Search all local mounted volumes, including the user home directory. The user’s home directory is searched even if it is a remote volume.
        case local
        
        /// Search all indexed local mounted volumes including the current user’s home directory (even if the home directory is remote).
        case localIndexed
        
        /// Search all user-mounted remote volumes.
        case network
        
        /// Search all indexed user-mounted remote volumes.
        case networkIndexed
        #endif
        
        /// Search all files in the Documents directories of the app’s iCloud container directories.
        case ubiquitousDocuments
        
        /// Search all files not in the Documents directories of the app’s iCloud container directories.
        case ubiquitousData
        
        /// Search for documents outside the app’s container. This search can locate iCloud documents that the user previously opened using a document picker view controller. This lets your app access the documents again without requiring direct user interaction. The result’s metadata items return a security-scoped URL for their url property.
        case accessibleUbiquitousExternalDocuments
        
        /// The corresponding value of the raw type.
        public var rawValue: String {
            switch self {
            #if os(macOS)
            case .home: return NSMetadataQueryUserHomeScope
            case .local: return NSMetadataQueryLocalComputerScope
            case .localIndexed: return NSMetadataQueryIndexedLocalComputerScope
            case .network: return NSMetadataQueryNetworkScope
            case .networkIndexed: return NSMetadataQueryIndexedNetworkScope
            #endif
            case .ubiquitousDocuments: return NSMetadataQueryUbiquitousDocumentsScope
            case .ubiquitousData: return NSMetadataQueryUbiquitousDataScope
            case .accessibleUbiquitousExternalDocuments: return NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope
            }
        }
    }
}
