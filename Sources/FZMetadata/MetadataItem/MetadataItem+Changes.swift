//
//  MetadataItem+Change.swift
//  
//
//  Created by Florian Zand on 01.05.25.
//

import Foundation
import FZSwiftUtils

extension MetadataItem {
    /// Represents the changed attributes between two states of a metadata item.
    public class Changes: CustomStringConvertible {
        private var values: [String: Any] = [:]
        private var previous: [String: Any] = [:]
        private var didParse = false
        private var _changed: Set<String> = []
        private var _remaining: Set<String> = []
        private var remaining: Set<String> {
            if !didParse {
                didParse = true
                _remaining = Set(values.keys).union(previous.keys)
            }
            return _remaining
        }
        
        /// The items that have changed between the current and previous item state.
        public var changedAttributes: [Attribute] {
            remaining.forEach({ _ = self[$0] })
            return Array(_changed).compactMap({ Attribute(rawValue: $0) })
        }
        
        /// A Boolean value indicating whether the specified attribute has changed between the current and previous item state.
        public func didChange(_ attribute: Attribute) -> Bool {
            self[attribute]
        }
        
        /// Returns the current and previous value for the specified attribute if it has changed.
        public func change(for attribute: Attribute) -> (value: Any, previous: Any)? {
            guard self[attribute.rawValue], let value = values[attribute.rawValue], let previous = previous[attribute.rawValue] else { return nil }
            return (value, previous)
        }
                
        /// Returns the current and previous value for the attribute at the specified key path, if it has changed.
        public func change<Value>(for keyPath: KeyPath<MetadataItem, Value>) -> (value: Value, previous: Value)? {
            let key = keyPath.mdItemKey
            guard self[key], let value = values[key] as? Value, let previous = previous[key] as? Value else { return nil }
            return (value, previous)
        }
        
        /// Returns the previous value for the attribute at the specified key path.
        public func previousValue<Value>(for keyPath: KeyPath<MetadataItem, Value>) -> Value? {
            previous[keyPath.mdItemKey] as? Value
        }
        
        /// Returns the current and previous values for the attribute at the specified key path, if the attribute has changed.
        public subscript<Value>(keyPath: KeyPath<MetadataItem, Value>) -> (value: Value, previous: Value)? {
            change(for: keyPath)
        }
        
        /// A Boolean value indicating whether the specified attribute has changed between the current and previous item state.
        public subscript(attribute: Attribute) -> Bool {
            self[attribute.rawValue]
        }
        
        public var description: String {
            "[\(changedAttributes.map({$0.description }).joined(separator: ", "))]"
        }
        
        subscript(attribute: String) -> Bool {
            if _changed.contains(attribute) {
                return true
            }
            guard remaining.contains(attribute) else { return false }
            _remaining.remove(attribute)
            switch (values[attribute], previous[attribute]) {
            case (nil, nil):
                return false
            case (nil, _), (_, nil):
                _changed.insert(attribute)
                return true
            case let (lhs as any Equatable, rhs as any Equatable):
                if !lhs.isEqual(rhs) {
                    _changed.insert(attribute)
                    return true
                }
            default:
                _changed.insert(attribute)
                return true
            }
            return false
        }
        
        func update(with newValues: [String : Any]) {
            previous = values
            values = newValues
            _changed = []
            _remaining = []
            didParse = false
        }
        
        init(values: [String : Any] = [:], previous: [String : Any] = [:]) {
            self.values = values
            self.previous = previous
        }
        
        func copy() -> Changes {
            Changes(values: values, previous: previous)
        }
        
        func changedAttributes(excluding: [Attribute]) -> [Attribute] {
            var remaining = remaining
            remaining.remove(excluding.map({$0.rawValue}))
            remaining.forEach({ _ = self[$0] })
            return Array(_changed).compactMap({ Attribute(rawValue: $0) })
        }
    }
}

extension MetadataQuery.ResultDifference {
    /// The changes between two query results.
    public class Changes: Hashable {
        private var changes: [MetadataItem: MetadataItem.Changes] = [:]
        private let id = UUID()
        
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
        
        /// Returns the metadata items that have changed for the specified attribute.
        public subscript(attribute: MetadataItem.Attribute) -> [MetadataItem] {
            changedItems(for: attribute)
        }
        
        /// Returns the items and values that have changed for the specified attribute.
        public subscript<V>(keyPath: KeyPath<MetadataItem, V>) -> [(item: MetadataItem, value: V, previousValue: V)] {
            changedValues(for: keyPath)
        }
        
        static let empty = Changes()
        
        init(_ items: [MetadataItem] = []) {
            items.forEach({ changes[$0] = $0.changes.copy()  })
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: Changes, rhs: Changes) -> Bool {
            lhs.id == rhs.id
        }
    }
}
