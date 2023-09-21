//
//  MetadataQuery+SortDescriptor.swift
//  
//
//  Created by Florian Zand on 10.02.23.
//

import Foundation

extension MetadataQuery {
    /** A description of how to order the result of a metadata query according to a metadata attribute.
    
        SortDescriptor can also be created by prependding `>>` (ascending) or `<<` (descending) to a metadata attribute.
     ```swift
      query.sortedBy = [>>.creationDate, <<.fileSize] // Sorts by ascending creationDate & descending fileSize
    ```
     */
    public class SortDescriptor: NSSortDescriptor {
        /// The order of sorting.
        public enum Order {
            /// Ascending sort order.
            case ascending
            /// Descending sort order.
            case descending
        }
        
        /*
        /**
         Creates a sort descriptor from a given metadata item kexpath.

         - Parameters:
            - keypath: The keypath to the comparable metadata attribute.
            - order: The order of the sorting.
         */
        public init(_ attribute: MetadataItem.Attribute, order: Order = .ascending) {
                super.init(key: attribute.rawValue, ascending: (order == .ascending))
        }
        
        */
        
        /**
         Creates a sort descriptor with ascending order from the specified metadata attribute.

         - Parameters:
            - keypath: The keypath to the comparable metadata attribute.
         */
        public static func asc(_ attribute: MetadataItem.Attribute) -> SortDescriptor  {
            SortDescriptor(key: attribute.rawValue, ascending: true)
        }
        
        /**
         Creates a sort descriptor with descending order from the specified metadata attribute.
         
         - Parameters:
            - keypath: The keypath to the comparable metadata attribute.
         */
        public static func desc(_ attribute: MetadataItem.Attribute) -> SortDescriptor  {
            SortDescriptor(key: attribute.rawValue, ascending: false)
        }
        

    }
}

// MARK: Operator

public prefix func >> (lhs: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(key: lhs.rawValue, ascending: true)
}

public prefix func << (lhs: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(key: lhs.rawValue, ascending: false)
}
