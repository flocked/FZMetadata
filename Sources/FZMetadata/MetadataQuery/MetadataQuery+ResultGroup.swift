//
//  MetadataQuery+ResultGroup.swift
//
//
//  Created by Florian Zand on 27.04.23.
//

import Foundation

public extension MetadataQuery {
    /// The results of a query grouped by the metadata attributes specified in ``groupingAttributes``.
    struct ResultGroup {
        /// The metadata attribute of the group.
        public let attribute: MetadataItem.Attribute
        
        /// An array containing the group’s metadata items.
        public let items: [MetadataItem]
        
        /// An array containing the group’s subgroups.
        public let subgroups: [ResultGroup]?
        
        init?(_ group: NSMetadataQueryResultGroup) {
            guard let attribute = MetadataItem.Attribute(rawValue: group.attribute) else { return nil }
            self.attribute = attribute
            items = (0..<group.resultCount).compactMap({ group.result(at: $0) as? MetadataItem })
            subgroups = group.subgroups?.compactMap { Self($0) }
        }
    }
}
