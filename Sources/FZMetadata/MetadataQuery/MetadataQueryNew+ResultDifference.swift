//
//  MetadataQuery+ResultDfference.swift
//
//
//  Created by Florian Zand on 27.04.23.
//

import Foundation

public extension MetadataQueryNew {
    /// The results difference of a query compared to the previous results.
    struct ResultsDifference: Hashable {
        /// Added items compared to the previous results.
        public let added: [MetadataItem]

        /// Removed items compared to the previous results.
        public let removed: [MetadataItem]

        /// Changed items compared to the previous results.
        public let changed: [MetadataItem]

        init(added: [MetadataItem] = [], removed: [MetadataItem] = [], changed: [MetadataItem] = []) {
            self.added = added
            self.removed = removed
            self.changed = changed
        }

        static var none: ResultsDifference {
            ResultsDifference()
        }

        static func added(_ items: [MetadataItem]) -> ResultsDifference {
            ResultsDifference(added: items)
        }
    }
}
