//
//  MetadataQuery+AttributeValueTuple.swift
//  
//
//  Created by Florian Zand on 14.04.25.
//

import Foundation
import FZSwiftUtils

extension MetadataQuery {
    /**
     A dictionary containing the unique values and their occurrences for each queried metadata uten attribute.
     
     Each ``AttributeValueTuple`` contains the attribute value, and the occurrences of that value that exist for the attribute name.
     
     To get the attribute/value mapped to the attributes value type, use MetadataItem's key path. For example:
     
     ```swift
     /// This returns [MappedAttributeValue<Date?>]
     let mappedValues = query.valueList[\.creationDate]
     ```
     */
    public var valueLists: [MetadataItem.Attribute: [AttributeValueTuple]] {
        query.valueLists.reduce(into: [:], { partialResult, val in
            guard let attribute = MetadataItem.Attribute(rawValue: val.key) else { return }
            partialResult[attribute] = val.value.map({ AttributeValueTuple(attribute, $0.value, $0.count)  })
        })
    }
    
    /// Represents a unique value found for a specific metadata attribute and the number of times that value occurs for the attribute.
    public struct AttributeValueTuple: CustomStringConvertible {
        /// The attribute name for the tuple’s value.
        public let attribute: MetadataItem.Attribute
        /// The value of the tuple’s attribute.
        public let value: Any?
        /// The number of instances of the value for the tuple’s attribute.
        public let count: Int
        
        public var description: String {
            "[value: \(value != nil ? "\(value!)": "-"), count: \(count)]"
        }
        
        func mapped<V>(to keyPath: KeyPath<MetadataItem, V>) -> MappedAttributeValueTuple<V>? {
            guard let value = value as? V else { return nil }
            return .init(attribute, value, count)
        }
        
        init(_ attribute: MetadataItem.Attribute, _ value: Any?, _ count: Int) {
            self.attribute = attribute
            self.value = value
            self.count = count
        }
    }
    
    /**
     A `MetadataItem` attribute-value tuple.
     
     Attribute-value tuples are returned by ``MetadataQuery`` as the results in the value lists. Each attribute/value tuple contains the attribute name, the value, and the number of instances of that value that exist for the attribute name.
     */
    public class MappedAttributeValueTuple<Value>: CustomStringConvertible {
        /// The attribute name for the tuple’s value.
        public let attribute: MetadataItem.Attribute
        /// The value of the tuple’s attribute.
        public let value: Value
        /// The number of instances of the value for the tuple’s attribute.
        public let count: Int
        
        public var description: String {
            "[value: \(value), count: \(count)]"
        }
        
        init(_ attribute: MetadataItem.Attribute, _ value: Value, _ count: Int) {
            self.value = value
            self.count = count
            self.attribute = attribute
        }
    }
}

extension [MetadataItem.Attribute: [MetadataQuery.AttributeValueTuple]] {
    public subscript <V>(keyPath: KeyPath<MetadataItem, V>) -> [MetadataQuery.MappedAttributeValueTuple<V>]? {
        guard let attribute = MetadataItem.Attribute(rawValue: keyPath.mdItemKey), let values = self[attribute] else { return nil }
        return values.compactMap({ $0.mapped(to: keyPath) })
    }
}
