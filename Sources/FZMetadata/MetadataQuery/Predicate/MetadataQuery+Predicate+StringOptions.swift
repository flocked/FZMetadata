//
//  MetadataQuery+Predicate+StringOptions.swift
//
//
//  Created by Florian Zand on 06.08.23.
//

import Foundation

extension MetadataQuery {
    /// Options for string comparison in a query predicate.
    struct PredicateStringOptions: OptionSet {
        /// Case-sensitive string comparison.
        public static let caseSensitive = Self(rawValue: 1 << 0)
        /// Diacritic-sensitive string comparison.
        public static let diacriticSensitive = Self(rawValue: 1 << 1)
        /// Matches words.
        public static let wordBased = Self(rawValue: 1 << 2)
        
        /// Case-sensitive string comparison.
        public static let c = Self.caseSensitive
        /// Diacritic-sensitive string comparison.
        public static let d = Self.diacriticSensitive
        /// Matches words.
        public static let w = Self.wordBased

        public let rawValue: Int8
        
        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }
        
        var options: NSComparisonPredicate.Options {
            var options: NSComparisonPredicate.Options = []
            if !contains(.caseSensitive) { options.insert(.caseInsensitive) }
            if !contains(.diacriticSensitive) { options.insert(.diacriticInsensitive) }
            if contains(.wordBased) { options.insert(.wordBased) }
            return options
        }
    }
}
