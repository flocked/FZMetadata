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
        /// Searches the user’s home directory.
        case home
        
        /**
         Searches all local mounted volumes, including the user's home directory.
         
         The user’s home directory is searched even if it is a remote volume.
         */
        case local
        
        /**
         Searches all indexed local mounted volumes including the user’s home directory.
         
         The user’s home directory is searched even if it is a remote volume.
         */
        case localIndexed
        
        /// Searches all user-mounted remote volumes.
        case network
        
        /// Searches all indexed user-mounted remote volumes.
        case networkIndexed
        #endif
        
        /// Searches all files in the Documents directories of the app’s iCloud container directories.
        case ubiquitousDocuments
        
        /// Searches all files not in the Documents directories of the app’s iCloud container directories.
        case ubiquitousData
        
        /// Searches for documents outside the app’s container. This search can locate iCloud documents that the user previously opened using a document picker view controller. This lets your app access the documents again without requiring direct user interaction. The result’s metadata items return a security-scoped URL for their url property.
        case accessibleUbiquitousExternalDocuments
        
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
