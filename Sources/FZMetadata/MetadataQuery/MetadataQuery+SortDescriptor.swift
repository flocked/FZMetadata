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
    open class SortDescriptor: NSSortDescriptor {
        /// The sorting metadata attribute.
        public let attribute: MetadataItem.Attribute
        
        init(attribute: MetadataItem.Attribute, ascending: Bool) {
            self.attribute = attribute
            super.init(key: attribute.rawValue, ascending: ascending)
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        /**
         An ascending sort descriptor for the specified metadata attribute.

         - Parameter attribute: The comparable metadata attribute.
         */
        public static func ascending(_ attribute: MetadataItem.Attribute) -> SortDescriptor {
            SortDescriptor(attribute: attribute, ascending: true)
        }

        /**
         A descending sort descriptor for the specified metadata attribute.

         - Parameter attribute: The comparable metadata attribute.
         */
        public static func descending(_ attribute: MetadataItem.Attribute) -> SortDescriptor {
            SortDescriptor(attribute: attribute, ascending: false)
        }
    }
}

// MARK: Operator

/**
 Returns an ascending metadata query sort descriptor for the specified metadata attribute.

 - Parameter attribute: The comparable metadata attribute.
 */
public prefix func >> (attribute: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(attribute: attribute, ascending: true)
}

/**
 Returns a descending metadata query sort descriptor for the specified metadata attribute.

 - Parameter attribute: The comparable metadata attribute.
 */
public prefix func << (attribute: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(attribute: attribute, ascending: false)
}
