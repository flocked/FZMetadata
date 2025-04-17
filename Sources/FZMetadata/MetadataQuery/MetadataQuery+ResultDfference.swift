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
    struct ResultsDifference: Hashable, CustomStringConvertible {
        /// Added items compared to the previous results.
        public let added: [MetadataItem]

        /// Removed items compared to the previous results.
        public let removed: [MetadataItem]

        /// Changed items compared to the previous results.
        public let changed: [MetadataItem]
        
        var isEmpty: Bool { self == ResultsDifference() }
        
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
            ResultsDifference(added: lhs.added + rhs.added, removed: lhs.removed + rhs.removed, changed: lhs.changed + rhs.changed)            
        }
        
        init(added: [MetadataItem] = [], removed: [MetadataItem] = [], changed: [MetadataItem] = []) {
            self.added = added
            self.removed = removed
            self.changed = changed
        }
    }
}

/*
class ResultsDifferenceAlt {
    /// Added items compared to the previous results.
    public let added: [MetadataItem]

    /// Removed items compared to the previous results.
    public let removed: [MetadataItem]

    /// Changed items compared to the previous results.
    public let changed: [MetadataItem]
    
    /// Dictionary of the changed attributes where the keys represent the attributes and their values the items.
    public var changedAttributes: [MetadataItem.Attribute : [MetadataItem]] {
        if !itemAttributeChanges.isEmpty {
            loadChangedAttributes()
        }
        return _changedAttributes
    }
    
    var itemAttributeChanges: [ItemAttributeChanges]
    var _changedAttributes: [MetadataItem.Attribute : [MetadataItem]] = [:]
    
    func loadChangedAttributes() {
        for change in itemAttributeChanges {
            for attribute in change.updatedAttributes {
                _changedAttributes[attribute] = (_changedAttributes[attribute] ?? []) + change.item
            }
        }
        itemAttributeChanges.removeAll()
    }
    
    init(added: [MetadataItem] = [], removed: [MetadataItem] = [], changed: [MetadataItem] = []) {
        self.added = added
        self.removed = removed
        self.changed = changed
        self.itemAttributeChanges = changed.compactMap({ ItemAttributeChanges($0) })
    }
    
    static func added(_ items: [MetadataItem]) -> ResultsDifferenceAlt {
        ResultsDifferenceAlt(added: items)
    }
    
    static var empty = ResultsDifferenceAlt()
    /*
    struct ItemAttributeChanges {
        let item: MetadataItem
        let previousValues: [String:Any]?
        let values: [String:Any]
        
        init(_ item: MetadataItem) {
            self.item = item
            self.previousValues = item.previousValues
            self.values = item.values
        }
        
        var updatedAttributes: [MetadataItem.Attribute] {
            guard let previousValues = item.previousValues else { return [] }
            let difference = values.difference(to: previousValues)
            return (difference.added + difference.removed + difference.changed).compactMap({MetadataItem.Attribute(rawValue: $0)})
        }
    }
    */
}
*/
