//
//  MetadataQuery+SortDescriptor.swift
//  
//
//  Created by Florian Zand on 10.02.23.
//

import Foundation

extension MetadataQuery {
    /** 
     A description of how to order the result of a query according to a metadata attribute.
    
     SortDescriptor can also be created by prependding `>>` (ascending) or `<<` (descending) to a metadata attribute.
     
     ```swift
      query.sortedBy = [>>.creationDate, <<.fileSize] // Sorts by ascending creationDate & descending fileSize
    ```
     */
    public class SortDescriptor: NSSortDescriptor {
        /// The order of sorting.
        enum Order {
            /// Ascending sort order.
            case ascending
            
            /// Descending sort order.
            case descending
        }
 
        /**
         An  ascending sort descriptor for the specified metadata attribute.

         - Parameter attribute: The comparable metadata attribute.
         */
        public static func ascending(_ attribute: MetadataItem.Attribute) -> SortDescriptor  {
            SortDescriptor(key: attribute.rawValue, ascending: true)
        }
        
        /**
         A  descending sort descriptor for the specified metadata attribute.
         
         - Parameter attribute: The comparable metadata attribute.
         */
        public static func descending(_ attribute: MetadataItem.Attribute) -> SortDescriptor  {
            SortDescriptor(key: attribute.rawValue, ascending: false)
        }
    }
}

// MARK: Operator

/**
 An  ascending sort descriptor for the specified metadata attribute.
 
 - Parameter attribute: The comparable metadata attribute.
 */
public prefix func >> (attribute: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(key: attribute.rawValue, ascending: true)
}

/**
 A  descending sort descriptor for the specified metadata attribute.
 
 - Parameter attribute: The comparable metadata attribute.
 */
public prefix func << (attribute: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(key: attribute.rawValue, ascending: false)
}
