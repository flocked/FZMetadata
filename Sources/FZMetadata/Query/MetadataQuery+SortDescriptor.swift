//
//  MetadataQuery+SortDescriptor.swift
//  
//
//  Created by Florian Zand on 10.02.23.
//

import Foundation

extension MetadataQuery {
    /** A description of how to order the result of a MetadataQuery according to a metadata attribute.
    
        SortDescriptor can also be created by prependding `>>` (ascending) or `<<` (descending) to a metadata attribute.
     ```swift
      query.sortedBy = [>>.fsCreationDate, <<.fsSize] // Sorts by ascending fsCreationDate & descending fsSize
    ```
     */
    public class SortDescriptor: NSSortDescriptor {
        public enum Order {
            case ascending
            case descending
        }
        
        /**
         Creates a sort descriptor from a given metadata item kexpath.

         - Parameters:
            - keypath: The keypath to the comparable metadata attribute.
            - order: The order of the sorting.
         */
        public init(_ attribute: Attribute, order: Order = .ascending) {
                super.init(key: attribute.rawValue, ascending: (order == .ascending))
        }
        
        /**
         Creates a sort descriptor with ascending order from a given metadata item attribute.
         
         - Parameters:
            - keypath: The keypath to the comparable metadata attribute.
         */
        public static func asc(_ attribute: Attribute) -> SortDescriptor  {
            SortDescriptor(attribute, order: .ascending)
        }
        
        /**
         Creates a sort descriptor with ascending order from a given metadata item attribute.
         
         - Parameters:
            - keypath: The keypath to the comparable metadata attribute.
         */
        public static func desc(_ attribute: Attribute) -> SortDescriptor  {
            SortDescriptor(attribute, order: .ascending)
        }
        
                
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: Operator

public prefix func >> (lhs: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(lhs, order: .ascending)
}

public prefix func << (lhs: MetadataItem.Attribute) -> MetadataQuery.SortDescriptor {
    MetadataQuery.SortDescriptor(lhs, order: .descending)
}
