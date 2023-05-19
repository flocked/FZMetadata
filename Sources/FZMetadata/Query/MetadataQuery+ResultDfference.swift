//
//  File.swift
//  
//
//  Created by Florian Zand on 27.04.23.
//

import Foundation

public extension MetadataQuery {
    struct Result {
        let items: [MetadataItem]
        let added: [MetadataItem]
        let removed: [MetadataItem]
        let changed: [MetadataItem]
                
        internal init(_ items: [MetadataItem], added: [MetadataItem] = [], removed: [MetadataItem] = [], changed: [MetadataItem] = []) {
            self.items = items
            self.added = added
            self.removed = removed
            self.changed = changed
        }
    }
}

public extension MetadataQuery {
    struct ResultDifference: Hashable {
        public let added: [MetadataItem]
        public let removed: [MetadataItem]
        public let changed: [MetadataItem]
        
        internal init(added: [MetadataItem] = [], removed: [MetadataItem] = [], changed: [MetadataItem] = []) {
            self.added = added
            self.removed = removed
            self.changed = changed
        }
                
        internal static var none: ResultDifference {
            return ResultDifference()
        }
        
        internal static func added(_ items: [MetadataItem]) -> ResultDifference {
            return ResultDifference(added: items)
        }
    }
}
