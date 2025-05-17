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

/*
 /// The attributes that have changed.
 public lazy var changedAttributes: [MetadataItem.Attribute] = {
     changes.values.reduce(into: []) {
         $0 += $1.changedAttributes(excluding: $0)
     }.uniqued()
 }()
 
 /// A Boolean value indicating whether the value of the specified attribute of an item has changed.
 public func didChange(_ attribute: MetadataItem.Attribute) -> Bool {
     changes.contains(where: { $0.value.didChange(attribute) })
 }
         
 /// Returns the items that have changed for the specified attribute.
 public func changedItems(for attribute: MetadataItem.Attribute) -> [MetadataItem] {
     changes.filter({ $0.value[attribute] }).compactMap({ $0.key })
 }
 
 /// Returns the items and values that have changed for the specified attribute.
 public func changedValues<V>(for keyPath: KeyPath<MetadataItem, V>) -> [(item: MetadataItem, value: V, previousValue: V)] {
     return changes.reduce(into: []) {
         guard let change = $1.value.change(for: keyPath) else { return }
         $0 += ($1.key, change.value, change.previous)
     }
 }
 */

extension Notification {
    var resultsUpdate: MetadataQuery.ResultDifference {
        .init(added: userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem] ?? [], removed: userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem] ?? [], changed: userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem] ?? [])
    }
}
