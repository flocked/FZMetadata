//
//  MetadataQuery+ResultGroup.swift
//  
//
//  Created by Florian Zand on 27.04.23.
//

import Foundation

public extension MetadataQuery {
    //// The ResultGroup represents a collection of grouped attribute results returned by an MetadataQuery object.
    struct ResultGroup {
        /// The result group’s attribute.
        var attribute: Attribute
        /// An array containing the result group’s metadata items.
        var items: [MetadataItem]
        /// An array containing the result group’s subgroups.
        var subgroups: [ResultGroup]?
        
        internal init?(nsResultGroup: NSMetadataQueryResultGroup) {
            if let attribute = Attribute(rawValue: nsResultGroup.attribute ) {
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
