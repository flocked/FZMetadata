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
        public static let c = Self(rawValue: 1 << 0)
        /// Diacritic-sensitive string comparison.
        public static let d = Self(rawValue: 1 << 1)
        /// Case and diacritical-sensitive string comparison.
        public static let cd: Self = [.c, .d]
        /// Matches words.
        public static let w = Self(rawValue: 1 << 2)
        static let cdw: Self = [.c, .d, .w]
        static let cw: Self = [.c, .w]
        static let dw: Self = [.d, .w]

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

        init(extracting value: String) {
            switch value {
            case _ where value.hasPrefix("$[c]"):
                self = .c
            case _ where value.hasPrefix("$[d]"):
                self = .d
            case _ where value.hasPrefix("$[w]"):
                self = .w
            case _ where value.hasPrefix("$[cd]"):
                self = .cd
            case _ where value.hasPrefix("$[dw]"):
                self = .dw
            case _ where value.hasPrefix("$[cw]"):
                self = .cd
            case _ where value.hasPrefix("$[cdw]"):
                self = .cdw
            default:
                self = []
            }
        }
    }
}

/*
 /// Options for how the query should search a string value.
 public struct StringOptions: OptionSet {
     public let rawValue: Int8
     public init(rawValue: Int8) {
         rawValue = rawValue
     }
     /// Case sensitive.
     public static let caseSensitive = StringOptions(rawValue: 1)
     /// Sensitive to diacritical marks.
     public static let diacriticSensitive = StringOptions(rawValue: 2)

     /// Case sensitive.
     public static let c = Self(rawValue: 1)
     /// Sensitive to diacritical marks.
     public static let d = Self(rawValue: 2)
     /// Case and diacritical sensitive.
     public static let cd: Self = [.c, .d]

     static let wordBased = StringOptions(rawValue: 3)
     static let w = Self(rawValue: 3)
     static let cdw: Self = [.c, .d, .w]
     static let cw: Self = [.c, .w]
     static let dw: Self = [.d, .w]

     var string: String {
         return "$[\(contains(.caseSensitive) ? "" : "c")\(contains(.diacriticSensitive) ? "" : "d")\(contains(.wordBased) ? "w" : "")]"
     }

     public init(extracting value: String) {
         switch value {
         case _ where value.hasPrefix("$[c]"):
             self = .c
         case _ where value.hasPrefix("$[d]"):
             self = .d
         case _ where value.hasPrefix("$[w]"):
             self = .w
         case _ where value.hasPrefix("$[cd]"):
             self = .cd
         case _ where value.hasPrefix("$[dw]"):
             self = .dw
         case _ where value.hasPrefix("$[cw]"):
             self = .cd
         case _ where value.hasPrefix("$[cdw]"):
             self = .cdw
         default:
             self = []
         }
     }

     static func extract(_ value: inout String) -> StringOptions {
         let options = StringOptions(extracting: value)
         value = value.replacingOccurrences(of: options.string, with: "")
         return options
     }
 }
 */
