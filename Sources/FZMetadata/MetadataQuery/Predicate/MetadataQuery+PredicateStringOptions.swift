//
//  MetadataQuery+PredicateStringOptions.swift
//
//
//  Created by Florian Zand on 06.08.23.
//

import Foundation

public extension MetadataQuery {
    /// Options for string comparison in metadata query predicates.
    struct PredicateStringOptions: OptionSet {
        /// Case-sensitive predicate.
        public static let caseSensitive = Self(rawValue: 1)
        /// Diacritic-sensitive predicate.
        public static let diacriticSensitive = Self(rawValue: 2)

        /// Case-sensitive predicate.
        public static let c = Self(rawValue: 1)
        /// Diacritic-sensitive predicate.
        public static let d = Self(rawValue: 2)
        /// Case and diacritical-sensitive predicate.
        public static let cd: Self = [.c, .d]

        static let wordBased = Self(rawValue: 3)
        static let w = Self(rawValue: 3)
        static let cdw: Self = [.c, .d, .w]
        static let cw: Self = [.c, .w]
        static let dw: Self = [.d, .w]

        public let rawValue: Int8
        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }

        var string: String {
            "$[\(contains(.caseSensitive) ? "" : "c")\(contains(.diacriticSensitive) ? "" : "d")\(contains(.wordBased) ? "w" : "")]"
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

        static func extract(_ value: inout String) -> Self {
            let options = Self(extracting: value)
            value = value.replacingOccurrences(of: options.string, with: "")
            return options
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
