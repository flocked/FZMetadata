//
//  MetadataQuery+ResultGroup.swift
//
//
//  Created by Florian Zand on 27.04.23.
//

import Foundation

public extension MetadataQuery {
    /// The result of a query grouped by the metadata attributes specified in ``groupingAttributes``.
    struct ResultGroup {
        /// The metadata attribute of the group.
        public var attribute: MetadataItem.Attribute

        /// An array containing the group’s metadata items.
        public var items: [MetadataItem]

        /// An array containing the group’s subgroups.
        public var subgroups: [ResultGroup]?

        init?(_ nsResultGroup: NSMetadataQueryResultGroup) {
            if let attribute = MetadataItem.Attribute(rawValue: nsResultGroup.attribute) {
                self.attribute = attribute
                var items = [MetadataItem]()
                for index in 0 ..< nsResultGroup.resultCount {
                    if let item = nsResultGroup.result(at: index) as? MetadataItem {
                        items.append(item)
                    }
                }
                self.items = items
                subgroups = nsResultGroup.subgroups?.compactMap { Self($0) }
            } else {
                return nil
            }
        }
    }
}
