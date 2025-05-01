//
//  MetadataQuery+ResultDfference.swift
//
//
//  Created by Florian Zand on 27.04.23.
//

import Foundation
import FZSwiftUtils

public extension MetadataQuery {
    /// The difference of a query results compared to the previous results.
    struct ResultDifference: Hashable, CustomStringConvertible {
        /// Items that were added compared to the previous results.
        public let added: [MetadataItem]

        /// Items that were removed from the previous results.
        public let removed: [MetadataItem]

        /// Items that have changed to the previous results.
        public let changed: [MetadataItem]
        
        /// The changes to the previous results.
        public internal(set) var changes: Changes = .empty
        
        var isEmpty: Bool { self == ResultDifference() }
        
        public var description: String {
            "[added:\(added.count), changed:\(changed.count), removed:\(removed.count)]"
        }
        
        var _description: String {
            var strings: [String] = []
            if !added.isEmpty { strings.append("added: \(added.count)") }
            if !removed.isEmpty { strings.append("removed: \(removed.count)") }
            if !changed.isEmpty { strings.append("changed: \(changed.count)") }
            return strings.isEmpty ? "" : "(\(strings.joined(separator: ", ")))"
        }
        
        static func + (lhs: Self, rhs: Self) -> Self {
            ResultDifference(added: lhs.added + rhs.added, removed: lhs.removed + rhs.removed, changed: lhs.changed + rhs.changed)            
        }
        
        init(added: [MetadataItem] = [], removed: [MetadataItem] = [], changed: [MetadataItem] = []) {
            self.added = added
            self.removed = removed
            self.changed = changed
        }
    }
}

extension Notification {
    var resultsUpdate: MetadataQuery.ResultDifference {
        .init(added: userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem] ?? [], removed: userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem] ?? [], changed: userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem] ?? [])
    }
}
