//
//  MetadataQuery+SortDescriptor.swift
//
//
//  Created by Florian Zand on 10.02.23.
//

import Foundation

extension MetadataQuery {
    /**
      A description of how to order the results of a query according to a metadata attribute.

      SortDescriptor can also be created by prependding `>>` ror an ascending, or `<<` (descending) to a metadata attribute.

      ```swift
       query.sortedBy = [>>.creationDate, <<.fileSize] // Sorts by ascending creationDate & descending fileSize
     ```
      */
    open class SortDescriptor {
        /// The metadata attribute of the sort descriptor.
        public let attribute: MetadataItem.Attribute
        
        /// A Boolean value that indicates whether the sort descriptor specifies sorting in ascending order.
        public let ascending: Bool
        
        init(_ attribute: MetadataItem.Attribute, ascending: Bool = true) {
            self.attribute = attribute
            self.ascending = ascending
        }
        
        /**
         An ascending sort descriptor for the specified metadata attribute.
         
         - Parameter attribute: The comparable metadata attribute.
         */
        public static func ascending(_ attribute: MetadataItem.Attribute) -> SortDescriptor {
            SortDescriptor(attribute, ascending: true)
        }
        
        /**
         A descending sort descriptor for the specified metadata attribute.
         
         - Parameter attribute: The comparable metadata attribute.
         */
        public static func descending(_ attribute: MetadataItem.Attribute) -> SortDescriptor {
            SortDescriptor(attribute, ascending: false)
        }
        
        var sortDescriptor: NSSortDescriptor {
            NSSortDescriptor(key: attribute.rawValue, ascending: ascending)
        }
    }
}
