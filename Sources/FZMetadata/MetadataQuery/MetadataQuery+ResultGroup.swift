//
//  MetadataQuery+ResultGroup.swift
//  
//
//  Created by Florian Zand on 27.04.23.
//

import Foundation

public extension MetadataQuery {
    /// The ResultGroup represents a collection of grouped attribute results returned by a metadata query.
    struct ResultGroup {
        /// The metadata attribute of the group.
        public var attribute: MetadataItem.Attribute
        /// An array containing the result group’s metadata items.
        public var items: [MetadataItem]
        /// An array containing the result group’s subgroups.
        public var subgroups: [ResultGroup]?
        
        internal init?(nsResultGroup: NSMetadataQueryResultGroup) {
            if let attribute = MetadataItem.Attribute(rawValue: nsResultGroup.attribute ) {
                self.attribute = attribute
                var items = [MetadataItem]()
                for index in 0..<nsResultGroup.resultCount {
                    if let item = nsResultGroup.result(at: index) as? MetadataItem {
                        items.append(item)
                    }
                }
                self.items = items
                self.subgroups =  nsResultGroup.subgroups?.compactMap({Self(nsResultGroup: $0)})
            } else {
                return nil
            }
        }
    }
}
