//
//  MetadataQuery+Predicate.swift
//
//
//  Created by Florian Zand on 21.04.23.
//

import Foundation
import FZSwiftUtils
import UniformTypeIdentifiers

extension NSPredicate {
    typealias Item = MetadataQuery.Predicate<MetadataItem>
    typealias BoolExpression = MetadataQuery.Predicate<Swift.Bool>

    convenience init?(metadataExpression: (Item) -> (BoolExpression)) {
        guard let predicateFormat = metadataExpression(.init()).predicate?.predicateFormat else { return nil }
        self.init(format: predicateFormat)
    }
}

public extension MetadataQuery {
    /**
     A predicate for filtering the results of a query.

     ### Operators
     Predicates can be defined by comparing MetadataItem properties to values using operators and functions.

     Depending on the property type there are different operators and functions available:

     ## General
     - ``Predicate-swift.struct/isFile``
     - ``Predicate-swift.struct/isDirectory``
     - ``Predicate-swift.struct/isAlias``
     - ``Predicate-swift.struct/isVolume``
     - ``Predicate-swift.struct/any``  (either file, directory, alias or volume)

     ```swift
     // is a file
     { $0.isFile }

     // is not an alias file
     { $0.isAlias == false }

     // is any
     { $0.any }
     ```

     ## Equatable
     - `==`
     - `!=`
     - `== [Value]`  // equales any
     - `!= [Value]` // equales none
     - `&&`
     - `||`
     - `!(_)`
     - ``Predicate-swift.struct/isNil``
     - ``Predicate-swift.struct/isNotNil``

     ```swift
     // fileName is "MyFile.doc" and creator isn't "Florian"
     query.predicate = { $0.fileName == "MyFile.doc" && $0.creater != "Florian"}

     // fileExtension is either "mp4", "mov" or "ts"
     query.predicate = { $0.fileExtension == ["mp4", "mov", "ts"] }

     // fileExtension isn't "mp3", "wav" and aiff
     query.predicate = { $0.fileExtension != ["mp3", "wav", "aiff"] }

     // downloadedDate is not nil
     query.predicate = { $0.downloadedDate.isNotNil }
     ```

     ## Comparable
     - `>`
     - `>=`
     - `<`
     - `<=`
     - `between(Range)` OR `== Range`

     ```swift
     // fileSize is greater than or equal to 1 gb
     { $0.fileSize.gigabytes >= 1 }

     // // fileSize is between 500 and 1000 mb
     { $0.fileSize.megabytes.between(500...1000) }
     { $0.fileSize.megabytes == 500...1000 }
     ```

     ## String
     - ``Predicate-swift.struct/begins(with:_:)`` OR  `*== String`
     - ``Predicate-swift.struct/ends(with:_:)`` OR  `==* String`
     - ``Predicate-swift.struct/contains(_:_:)`` OR `*=* String`

     ```swift
     // fileName ends with ".doc"
     { $0.fileName.ends(with: ".doc") }
     { $0.fileName ==*  ".doc" }

     // fileName contains "MyFile"
     { $0.fileName.contains("MyFile") }
     { $0.fileName *=*  "MyFile" }
     ```

     By default string predicates are case and diacritic-insensitive.

     Use ``PredicateStringOptions/c`` for case-sensitive, ``PredicateStringOptions/d``, for diacritic-sensitve and ``PredicateStringOptions/cd`` for both case & diacritic sensitive predicates.

     ```swift
     // case-sensitive
     { $0.fileName.begins(with: "MyF", .c) }

     // case and diacritic-sensitive
     { $0.fileName.begins(with: "MyF", .cd) }
     ```

     ## Date
     - ``Predicate-swift.struct/isNow``
     - ``Predicate-swift.struct/isToday``
     - ``Predicate-swift.struct/isYesterday``
     - ``Predicate-swift.struct/isSameDay(as:)``
     - ``Predicate-swift.struct/isThisWeek``
     - ``Predicate-swift.struct/isLastWeek``
     - ``Predicate-swift.struct/isSameWeek(as:)``
     - ``Predicate-swift.struct/isThisMonth``
     - ``Predicate-swift.struct/isLastMonth``
     - ``Predicate-swift.struct/isSameMonth(as:)``
     - ``Predicate-swift.struct/isThisYear``
     - ``Predicate-swift.struct/isLastYear``
     - ``Predicate-swift.struct/isSameYear(as:)``
     - ``Predicate-swift.struct/isBefore(_:)``
     - ``Predicate-swift.struct/isAfter(_:)``
     - ``Predicate-swift.struct/within(_:_:)``

     ```swift
     // is today
     { $0.creationDate.isToday }

     // is same week as otherDate
     { $0.creationDate.isSameWeek(as: otherDate) }

     // is within 4 weeks
     { $0.creationDate.within(4, .week) }
     ```

     ## Collection
     - ``Predicate-swift.struct/contains(_:)``  OR `== Element`
     - ``Predicate-swift.struct/containsNot(_:)``  OR `!= Element`
     - ``Predicate-swift.struct/contains(any:)``
     - ``Predicate-swift.struct/containsNot(any:)``

     ```swift
     // finderTags contains "red"
     { $0.finderTags.contains("red") }
     { $0.finderTags == "red" }

     // finderTags doesn't contain "red"
     { $0.finderTags.containsNot("blue") }
     { $0.finderTags != "red" }

     // finderTags contains "red", "yellow" or `green`.
     { $0.finderTags.contains(any: ["red", "yellow", "green"]) }

     // finderTags doesn't contain "red", "yellow" or `green`.
     { $0.finderTags.containsNot(any: ["red", "yellow", "green"]) }
     ```
     */
    @dynamicMemberLookup
    struct Predicate<T> {
        typealias ComparisonOperator = NSComparisonPredicate.Operator

        /// This initaliser should be used from callers who require queries on primitive collections.
        init(_ mdKey: String) {
            self.mdKey = mdKey
            self.predicate = nil
        }

        init(_ predicate: NSPredicate) {
            self.mdKey = "Root"
            self.predicate = predicate
        }

        init() {
            self.mdKey = "Root"
            self.predicate = nil
        }

        let mdKey: String

        let predicate: NSPredicate?

        /// All mdKeys used for the predicate.
        var mdKeys: [String] {
            predicate?.predicateFormat.matches(pattern: #"\bkMDItem[a-zA-Z]*\b"#).compactMap(\.string).uniqued() ?? []
        }

        /// All attributes used for the predicate.
        var attributes: [MetadataItem.Attribute] {
            mdKeys.compactMap { MetadataItem.Attribute(rawValue: $0) }
        }

        /// Returns the metadata attribute for the specified `MetadataItem` keypath.
        public subscript(dynamicMember member: KeyPath<MetadataItem, Bool?>) -> MetadataQuery.Predicate<Bool> where T == MetadataItem {
            .comparison(member.mdItemKey, .equalTo, true)
        }

        /// Returns the metadata attribute for the specified `MetadataItem` keypath.
        public subscript<V>(dynamicMember member: KeyPath<MetadataItem, V>) -> MetadataQuery.Predicate<V> where T == MetadataItem {
            .init(member.mdItemKey)
        }

        static func and(_ predicates: [MetadataQuery.Predicate<Bool>]) -> MetadataQuery.Predicate<Bool> {
            .init(NSCompoundPredicate(and: predicates.compactMap(\.predicate)))
        }

        static func or(_ predicates: [MetadataQuery.Predicate<Bool>]) -> MetadataQuery.Predicate<Bool> {
            .init(NSCompoundPredicate(or: predicates.compactMap(\.predicate)))
        }

        static func not(_ predicate: MetadataQuery.Predicate<Bool>) -> MetadataQuery.Predicate<Bool> {
            .init(NSCompoundPredicate(not: predicate.predicate!))
        }
        
        static func comparison(_ mdKey: String, _ type: ComparisonOperator = .equalTo, _ value: Any, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.comparison(mdKey, type, value, options))
        }

        static func comparisonAnd(_ mdKey: String, _ comparisonOperator: ComparisonOperator = .equalTo, _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = [[]]) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.comparisonAnd(mdKey, comparisonOperator, values, options))
        }

        static func comparisonOr(_ mdKey: String, _ comparisonOperator: ComparisonOperator = .equalTo, _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = [[]]) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.comparisonOr(mdKey, comparisonOperator, values, options))
        }
        
        static func between(_ mdKey: String, value1: Any, value2: Any) -> MetadataQuery.Predicate<Bool> {
            .and([
                .comparison(mdKey, .greaterThanOrEqualTo, value1),
                .comparison(mdKey, .lessThanOrEqualTo, value2)])
        }
        
        static func between(_ mdKey: String, values: [(Any, Any)]) -> MetadataQuery.Predicate<Bool> {
            .or(values.compactMap({ between(mdKey, value1: $0.0, value2: $0.1) }))
        }
        
        static func date(_ mdKey: String, _ queryDate: QueryDateRange) -> MetadataQuery.Predicate<Bool> {
            let values = queryDate.values
            return .between(mdKey, value1: values[0], value2: values[1])
        }
    }
}

// MARK: MetadataItem

public extension MetadataQuery.Predicate where T == MetadataItem {
    /// The item is either a file, directory, volume or alias file.
    var any: MetadataQuery.Predicate<String> {
        .init("*")
    }

    /// Checks if an item is a file.
    var isFile: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.data")
    }

    /// Checks if an item is a directory.
    var isDirectory: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.folder")
    }

    internal var isItem: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.item")
    }

    /// Checks if an item is a volume.
    var isVolume: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.volume")
    }

    /// Checks if an item is a alias file.
    var isAlias: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "com.apple.alias-file")
    }
}

// MARK: Bool

public extension MetadataQuery.Predicate where T == Bool {
    static prefix func ! (_ lhs: Self) -> MetadataQuery.Predicate<Bool> {
        .not(lhs)
    }

    static func && (_ lhs: Self, _ rhs: Self) -> MetadataQuery.Predicate<Bool> {
        .and([lhs, rhs])
    }

    static func || (_ lhs: Self, _ rhs: Self) -> MetadataQuery.Predicate<Bool> {
        .or([lhs, rhs])
    }
}

// MARK: Equatable

public extension MetadataQuery.Predicate where T: QueryEquatable {
    /// Checks if an element isn't nil.
    var isNotNil: MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .like, "*")
    }

    /// Checks if an element is nil.
    var isNil: MetadataQuery.Predicate<Bool> {
        .not(isNotNil)
    }

    /// Checks if an element equals a given value.
    static func == (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs.mdKey, .equalTo, rhs)
        } else {
            let isNotNil: MetadataQuery.Predicate<Bool> = .comparison(lhs.mdKey, .like, "*")
            return .not(isNotNil)
        }
    }

    /// Checks if an element doesn't equal a given value.
    static func != (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs.mdKey, .notEqualTo, rhs)
        } else {
            return .comparison(lhs.mdKey, .like, "*")
        }
    }

    /// Checks if an element equals any given values.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .comparisonOr(lhs.mdKey, .equalTo, Array(rhs))
    }

    /// Checks if an element doesn't equal given values.
    static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .comparisonAnd(lhs.mdKey, .notEqualTo, Array(rhs))
    }

    /// Checks if an element equals any given values.
    func `in`<C>(_ collection: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .comparisonOr(mdKey, .equalTo, Array(collection))
    }
}

// MARK: Comparable

public extension MetadataQuery.Predicate where T: QueryComparable {
    /// Checks if an element is greater than a given value.
    static func > (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .greaterThan, rhs)
    }

    /// Checks if an element is greater than or equal to given value.
    static func >= (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .greaterThanOrEqualTo, rhs)
    }

    /// Checks if an element is less than a given value.
    static func < (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .lessThan, rhs)
    }

    /// Checks if an element is less than or equal to given value.
    static func <= (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .lessThanOrEqualTo, rhs)
    }

    /// Checks if an element is between a given range.
    func between(_ range: Range<T>) -> MetadataQuery.Predicate<Bool> {
        .between(mdKey, value1: range.lowerBound, value2: range.upperBound)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: Range<T>) -> MetadataQuery.Predicate<Bool> {
        .between(lhs.mdKey, value1: rhs.lowerBound, value2: rhs.upperBound)
    }

    /// Checks if an element is between a given range.
    func between(_ range: ClosedRange<T>) -> MetadataQuery.Predicate<Bool> {
        .between(mdKey, value1: range.lowerBound, value2: range.upperBound)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: ClosedRange<T>) -> MetadataQuery.Predicate<Bool> {
        .between(lhs.mdKey, value1: rhs.lowerBound, value2: rhs.upperBound)
    }

    /// Checks if an element is between any given range.
    func between<C>(any ranges: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(mdKey, values: ranges.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(lhs.mdKey, values: rhs.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    func between<C>(any ranges: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(mdKey, values: ranges.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(lhs.mdKey, values: rhs.compactMap({($0.lowerBound, $0.upperBound)}))
    }
}

// MARK: Date

public extension MetadataQuery.Predicate where T: QueryDate {
    /// Checks if a date is now.
    var isNow: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .now)
    }

    /// Checks if a date is this hour.
    var isThisHour: MetadataQuery.Predicate<Bool> {
         .date(mdKey, .this(.hour))
    }

    /// Checks if a date is today.
    var isToday: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .today)
    }

    /// Checks if a date was yesterday.
    var isYesterday: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .yesterday)
    }

    /// Checks if a date is the same day as a given date.
    func isSameDay(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .date(mdKey, .same(.day, date))
    }

    /// Checks if a date is this week.
    var isThisWeek: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .this(.weekOfYear))
    }

    /// Checks if a date is last week.
    var isLastWeek: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .last(1, .weekOfYear))
    }

    /// Checks if a date is the same week as a given date.
    func isSameWeek(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .date(mdKey, .same(.weekOfYear, date))
    }

    /// Checks if a date is this month.
    var isThisMonth: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .this(.month))
    }

    /// Checks if a date is last month.
    var isLastMonth: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .last(1, .month))
    }

    /// Checks if a date is the same month as a given date.
    func isSameMonth(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .date(mdKey, .same(.month, date))
    }

    /// Checks if a date is this year.
    var isThisYear: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .this(.year))
    }

    /// Checks if a date is last year.
    var isLastYear: MetadataQuery.Predicate<Bool> {
        .date(mdKey, .last(1, .year))
    }

    /// Checks if a date is the same year as a given date.
    func isSameYear(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .date(mdKey, .same(.year, date))
    }

    /// Checks if a date is before a given date .
    func isBefore(_ date: Date) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .lessThan, date)
    }

    /// Checks if a date is after a given date .
    func isAfter(_ date: Date) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .greaterThan, date)
    }

    /**
     Checks if a date is at the same calendar unit as today.

     Example:
     ```swift
     // creationDate was this week.
     { $0.creationDate.this(.week) }

     // creationDate was this year.
     { $0.creationDate.this(.year) }
     ```
     */
    func this(_ unit: Calendar.Component) -> MetadataQuery.Predicate<Bool> {
        .date(mdKey, .this(unit))
    }

    /**
     Checks if a date is within the last `amout` of  calendar units.

     Example:
     ```swift
     // creationDate was within the last 8 weeks.
     { $0.creationDate.within(8, .week) }

     // creationDate was within the last 2 years.
     { $0.creationDate.within(2, .year) }
     ```
     */
    func within(_ amout: Int, _ unit: Calendar.Component) -> MetadataQuery.Predicate<Bool> {
        .date(mdKey, .last(amout, unit))
    }

    /// Checks if a date is between the specified date interval.
    func between(_ interval: DateInterval) -> MetadataQuery.Predicate<Bool> {
        .between(mdKey, value1: interval.start, value2: interval.end)
    }

    /*
     /// Checks if a date is last week.
      public var isWeekday:  MetadataQuery.Predicate<Bool> {
          .init(query(for: .last(1, .year), mdKey: mdKey))
      }

     /// Checks if a date is last week.
      public var isWeekend:  MetadataQuery.Predicate<Bool> {
          .init(query(for: .last(1, .year), mdKey: mdKey))
      }
      */
}

// MARK: UTType

@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
public extension MetadataQuery.Predicate where T: QueryUTType {
    /// Checks iif the content type is a subtype of a given type.
    func subtype(of type: UTType) -> MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, type.identifier)
    }

    /// Checks iif the content type is a subtype of any given type.
    func subtype<C: Collection<UTType>>(of anyTypes: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr("kMDItemContentTypeTree", .equalTo, Array(anyTypes))
    }

    /// Checks iif the content type is equal to a given type.
    static func == (_: Self, _ rhs: UTType) -> MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentType", .equalTo, rhs.identifier)
    }

    /// Checks iif the content type is equal to any given type.
    static func == <C: Collection<UTType>>(_: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr("kMDItemContentType", .equalTo, Array(rhs))
    }
}

// MARK: String

public extension MetadataQuery.Predicate where T: QueryString {
    /**
     Checks if a string contains a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func contains(_ value: String, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .contains, value, options)
    }

    /**
     Checks if a string contains any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func contains<C: Collection<String>>(any values: C, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(mdKey, .contains, Array(values), [options])
    }

    /**
     Checks if a string begins with a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func begins(with value: String, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .beginsWith, value, options)
    }

    /**
     Checks if a string begins with any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func begins<C: Collection<String>>(withAny values: C, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(mdKey, .beginsWith, Array(values), [options])
    }

    /**
     Checks if a string ends with a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func ends(with value: String, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .endsWith, value, options)
    }

    /**
     Checks if a string ends with any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func ends<C: Collection<String>>(withAny values: C, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(mdKey, .endsWith, Array(values), [options])
    }

    /**
     Checks if a string equals to a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func equals(_ value: String, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .equalTo, value, options)
    }

    /**
     Checks if a string equals to any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func equals<C: Collection<String>>(any values: C, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(mdKey, .equalTo, Array(values), [options])
    }

    /**
     Checks if a string doesn't equal to a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func equalsNot(_ value: String, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .notEqualTo, value, options)
    }

    /**
     Checks if a string doesn't equal to any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query (e.g. `caseSensitive` or `diacriticSensitive`).
     */
    func equalsNot<C: Collection<String>>(_ values: C, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(mdKey, .notEqualTo, Array(values), [options])
    }

    /// Checks if a string begins with a given string.
    static func *== (_ lhs: MetadataQuery.Predicate<T>, _ value: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .beginsWith, value)
    }

    /// Checks if a string begins with any of the given strings.
    static func *== <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(lhs.mdKey, .beginsWith, Array(values))
    }

    /// Checks if a string contains a given string.
    static func *=* (_ lhs: MetadataQuery.Predicate<T>, _ rhs: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .contains, rhs)
    }

    /// Checks if a string contains any of the given strings.
    static func *=* <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(lhs.mdKey, .contains, Array(values))
    }

    /// Checks if a string ends with a given string.
    static func ==* (_ lhs: MetadataQuery.Predicate<T>, _ rhs: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .endsWith, rhs)
    }

    /// Checks if a string ends with any of the given strings.
    static func ==* <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(lhs.mdKey, .endsWith, Array(values))
    }
}

// MARK: Collection

public extension MetadataQuery.Predicate where T: QueryCollection {
    /// Checks if the collection contains the given value.
    func contains(_ value: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .equalTo, value)
    }

    /// Checks if the collection doesn't contain the given value.
    func containsNot(_ value: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .notEqualTo, value)
    }

    /// Checks if the collection contains any of the given elements.
    func contains<U: Sequence>(any collection: U) -> MetadataQuery.Predicate<Bool> where U.Element == T.Element {
        .comparisonOr(mdKey, .equalTo, Array(collection))
    }

    /// Checks if the collection doesn't contain any of the given elements.
    func containsNot<U: Sequence>(any collection: U) -> MetadataQuery.Predicate<Bool> where U.Element == T.Element {
        .comparisonAnd(mdKey, .notEqualTo, Array(collection))
    }

    /// Checks if the collection contains the given value.
    static func == (_ lhs: MetadataQuery.Predicate<T>, _ rhs: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .equalTo, rhs)
    }

    /// Checks if the collection doesn't contain the given value.
    static func != (_ lhs: MetadataQuery.Predicate<T>, _ rhs: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .notEqualTo, rhs)
    }
}

// MARK: PredicateBuilder

extension MetadataQuery.Predicate {
    enum PredicateBuilder {
        
        static func comparison(_ mdKey: String, _ type: ComparisonOperator, _ value: Any, _ options: MetadataQuery.PredicateStringOptions = []) -> NSPredicate {
            var value = value
            switch (mdKey, value) {
            case let (_, value as String):
                if !value.hasPrefix("$time") {
                    return comparisonString(mdKey, type, value, options)
                }
            case let (_, value as CGSize):
                return comparisonSize(mdKey, type, value)
            case let (_, rect as CGRect):
                value = [rect.origin.x, rect.origin.y, rect.width, rect.height]
            //    case (_, let value as QueryStringOption):
            //        return queryString(mdKey, type, value)
            case let (_, _value as (any QueryRawRepresentable)):
                value = _value.rawValue
            default: break
            }

            let key = NSExpression(forKeyPath: mdKey)
            let valueEx = NSExpression(forConstantValue: value)
            return NSComparisonPredicate(leftExpression: key, rightExpression: valueEx, modifier: .direct, type: type)
        }
        
        static func comparisonAnd(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = []) -> NSPredicate {
            let predicates = values.enumerated().compactMap { comparison(mdKey, type, $0.element, options[safe: $0.offset] ?? options.last ?? []) }
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(and: predicates)
        }

        static func comparisonOr(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = []) -> NSPredicate {
            let predicates = values.enumerated().compactMap { comparison(mdKey, type, $0.element, options[safe: $0.offset] ?? options.last ?? []) }
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(or: predicates)
        }

        static func comparisonSize(_ mdKey: String, _ type: ComparisonOperator, _ value: CGSize) -> NSPredicate {
            let widthMDKey = mdKey.replacingOccurrences(of: "Size", with: "Width")
            let heightMDKey = mdKey.replacingOccurrences(of: "Size", with: "Height")
            let predicates = [comparison(widthMDKey, type, [value.width]), comparison(heightMDKey, type, [value.height])]
            return NSCompoundPredicate(and: predicates)
        }
        
        static func comparionString(for string: String, mdKey: String, _ type: ComparisonOperator, _ options: MetadataQuery.PredicateStringOptions? = []) -> String {
            var mdKey = mdKey
            var value = string
            var options = options ?? []
            options.insert(MetadataQuery.PredicateStringOptions.extract(&value))
            let predicateString: String
            if mdKey == "kMDItemFSExtension" {
                mdKey = "kMDItemFSName"
                predicateString = "\(mdKey) = '*.\(value)'\(options.string)"
            } else {
                switch type {
                case .contains:
                    predicateString = "\(mdKey) = '*\(value)*'\(options.string)"
                case .beginsWith:
                    predicateString = "\(mdKey) = '\(value)*'\(options.string)"
                case .endsWith:
                    predicateString = "\(mdKey) = '*\(value)'\(options.string)"
                case .notEqualTo:
                    predicateString = "\(mdKey) != '\(value)'\(options.string)"
                default:
                    predicateString = "\(mdKey) = '\(value)'\(options.string)"
                }
            }
            return predicateString
        }
        
        static func comparisonString(_ mdKey: String, _ type: ComparisonOperator, _ value: String, _ options: MetadataQuery.PredicateStringOptions? = []) -> NSPredicate {
            var mdKey = mdKey
            var value = value
            var options = options ?? []
            options.insert(MetadataQuery.PredicateStringOptions.extract(&value))
            let predicateString: String
            if mdKey == "kMDItemFSExtension" {
                mdKey = "kMDItemFSName"
                predicateString = "\(mdKey) = '*.\(value)'\(options.string)"
            } else {
                switch type {
                case .contains:
                    predicateString = "\(mdKey) = '*\(value)*'\(options.string)"
                case .beginsWith:
                    predicateString = "\(mdKey) = '\(value)*'\(options.string)"
                case .endsWith:
                    predicateString = "\(mdKey) = '*\(value)'\(options.string)"
                case .notEqualTo:
                    predicateString = "\(mdKey) != '\(value)'\(options.string)"
                default:
                    predicateString = "\(mdKey) = '\(value)'\(options.string)"
                }
            }
            #if os(macOS)
                return NSPredicate(fromMetadataQueryString: predicateString)!
            #else
                return NSPredicate(format: predicateString)
            #endif
        }
        
        /*
         static func queryString(_ mdKey: String, _ type: ComparisonOperator, _ queryString: QueryStringOption) -> NSPredicate {
                 return string(mdKey, type, queryString.value, queryString.options)
         }
          */
    }
}

// MARK: Protocols

/// Conforms equatable to be used in a metadata query predicate.
public protocol QueryEquatable { }
extension Optional: QueryEquatable where Wrapped: QueryEquatable { }

/// Conforms comparable to be used in a metadata query predicate.
public protocol QueryComparable: Comparable { }
extension Optional: QueryComparable where Wrapped: QueryComparable { }
extension Optional: Comparable where Wrapped: Comparable {
    public static func < (lhs: Optional, rhs: Optional) -> Bool {
        if let lhs = lhs, let rhs = rhs { return lhs < rhs }
        return false
    }
}

protocol QueryRawRepresentable: QueryEquatable {
    associatedtype RawValue
    var rawValue: RawValue { get }
}

extension DataSize: QueryRawRepresentable {
    public var rawValue: Int { bytes }
}

extension TimeDuration: QueryRawRepresentable, QueryComparable {
    public var rawValue: Double { seconds }
}

extension FileType: QueryRawRepresentable, QueryEquatable {
    public var rawValue: String { identifier ?? "other" }
}

/// Conforms `String` to be used in a metadata query predicate.
public protocol QueryString: QueryEquatable { }
extension String: QueryString { }
extension Optional: QueryString where Wrapped: QueryString { }

/// Conforms `Date` to be used in a metadata query predicate.
public protocol QueryDate: QueryComparable, QueryEquatable { }
extension Date: QueryDate {}
extension Optional: QueryDate where Wrapped: QueryDate { }

@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
extension UTType: QueryRawRepresentable {
    public var rawValue: String { identifier }
}

/// Conforms `UTType` to be used in a metadata query predicate.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
public protocol QueryUTType {}
@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
extension UTType: QueryUTType {}
@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
extension Optional: QueryUTType where Wrapped == UTType {}

/// Conforms `Collection` to be used in a metadata query predicate.
public protocol QueryCollection: QueryEquatable { associatedtype Element }
extension Array: QueryCollection { }
extension Set: QueryCollection { }
extension Optional: QueryCollection where Wrapped: QueryCollection {
    public typealias Element = Wrapped.Element
}

extension Int: QueryComparable, QueryEquatable { }
extension Int8: QueryComparable, QueryEquatable { }
extension Int16: QueryComparable, QueryEquatable { }
extension Int32: QueryComparable, QueryEquatable { }
extension Int64: QueryComparable, QueryEquatable { }
extension UInt: QueryComparable, QueryEquatable { }
extension UInt8: QueryComparable, QueryEquatable { }
extension UInt16: QueryComparable, QueryEquatable { }
extension UInt32: QueryComparable, QueryEquatable { }
extension UInt64: QueryComparable, QueryEquatable { }
extension Float: QueryComparable, QueryEquatable { }
extension Double: QueryComparable, QueryEquatable { }
extension CGFloat: QueryComparable, QueryEquatable { }
extension DataSize: QueryComparable, QueryEquatable { }

protocol AnyRange {
    associatedtype Bound
    var lowerBound: Bound { get }
    var upperBound: Bound { get }
}

extension Range: AnyRange {}
extension ClosedRange: AnyRange {}

extension URLUbiquitousItemDownloadingStatus: QueryRawRepresentable { }
extension URLUbiquitousSharedItemPermissions: QueryRawRepresentable { }

// MARK: QueryDateRange

enum QueryDateRange {
    case now
    case today
    case yesterday
    case tomorrow
    case this(Calendar.Component)
    case previous(Calendar.Component)
    case next(Calendar.Component)
    case last(Int, Calendar.Component)
    case sameDay(Date)
    case same(Calendar.Component, Date)
    
    var values: [String] {
        switch self {
        case .now:
            return ["$time.now", "$time.now(+10)"]
        case .today:
            return ["$time.today", "$time.today(+1)"]
        case .yesterday:
            return ["$time.today(-1)", "$time.today"]
        case .tomorrow:
            return ["$time.today(+1)", "$time.today(+2)"]
        case let .this(unit):
            if let values = values(for: unit) {
                return ["\(values.0)", "\(values.0)(+\(values.1 * 1))"]
            }
        case let .next(unit):
            if let values = values(for: unit) {
                return ["\(values.0)(+\(values.1 * 1))", "\(values.0)(+\(values.1 * 2))"]
            }
        case let .previous(unit):
            if let values = values(for: unit) {
                return ["\(values.0)(-\(values.1 * 2))", "\(values.0)(-\(values.1 * 1))"]
            }
        case let .last(value, unit):
            if let values = values(for: unit) {
                return ["\(values.0)", "\(values.0)(\(values.1 * value)"]
            }
        case let .sameDay(day):
            return ["\(day.beginning(of: .day) ?? day)", "\(day.end(of: .day) ?? day)"]
        case let .same(unit, date):
            return ["\(date.beginning(of: unit) ?? date)", "\(date.end(of: unit) ?? date)"]
        }
        return ["$time.today(-1)", "$time.today"]
    }
    
    func values(for unit: Calendar.Component) -> (String, Int)? {
        switch unit {
        case .second: return ("$time.now", 1)
        case .minute: return ("$time.now", 60)
        case .hour: return ("$time.now", 3600)
        case .day, .weekday: return ("$time.today", 1)
        case .weekOfMonth, .weekOfYear: return ("$time.this_week", 1)
        case .month: return ("$time.this_month", 1)
        case .quarter: return ("$time.this_month", 3)
        case .year: return ("$time.this_year", 1)
        default: return nil
        }
    }
}

// MARK: FileType + Predicate

extension FileType {
    var metadataPredicate: NSPredicate {
        let key: NSExpression
        let type: NSComparisonPredicate.Operator
        switch self {
        case .executable, .folder, .image, .video, .audio, .pdf, .presentation:
            key = NSExpression(forKeyPath: "_kMDItemGroupId")
            type = .equalTo
        case .aliasFile, .application, .archive, .diskImage, .text, .gif, .document, .symbolicLink, .other:
            key = NSExpression(forKeyPath: "kMDItemContentTypeTree")
            type = .like
        }
        let value: NSExpression
        switch self {
        case .executable: value = NSExpression(format: "%i", 8)
        case .folder: value = NSExpression(format: "%i", 9)
        case .image: value = NSExpression(format: "%i", 13)
        case .video: value = NSExpression(format: "%i", 7)
        case .audio: value = NSExpression(format: "%i", 10)
        case .pdf: value = NSExpression(format: "%i", 11)
        case .presentation: value = NSExpression(format: "%i", 12)
        case .application: value = NSExpression(format: "%@", "com.apple.application")
        case .archive: value = NSExpression(format: "%@", "com.apple.public.archive")
        case .diskImage: value = NSExpression(format: "%@", "public.disk-image")
        case .gif: value = NSExpression(format: "%@", "com.compuserve.gif")
        case .document: value = NSExpression(format: "%@", "public.content")
        case .text: value = NSExpression(format: "%@", "public.text")
        case .aliasFile: value = NSExpression(format: "%@", "com.apple.alias-file")
        case .symbolicLink: value = NSExpression(format: "%@", "public.symlink")
        case let .other(oValue): value = NSExpression(format: "%@", oValue)
        }

        let modifier: NSComparisonPredicate.Modifier
        switch self {
        case .application, .archive, .text, .document, .other:
            modifier = .any
        default:
            modifier = .direct
        }
        return NSComparisonPredicate(leftExpression: key, rightExpression: value, modifier: modifier, type: type)
    }
}


// MARK: String

/*
 extension MetadataQuery.Predicate where T: QueryString {
     public func begins<C: Collection<QueryString>>(with values: C) -> MetadataQuery.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .beginsWith, values.first!) : .or(mdKey, .beginsWith, values)
     }

     public func begins(with values: QueryString...) -> MetadataQuery.Predicate<Bool> {
         self.begins(with: values)
     }

     public func contains<C: Collection<QueryString>>(_ values: C) -> MetadataQuery.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .contains, values.first!) : .or(mdKey, .contains, values)
     }

     public func contains(_ values: QueryString...) -> MetadataQuery.Predicate<Bool> {
         self.contains(values)
     }

     public func ends<C: Collection<QueryString>>(with values: C) -> MetadataQuery.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .endsWith, values.first!) : .or(mdKey, .endsWith, values)
     }

     public func ends(with values: QueryString...) -> MetadataQuery.Predicate<Bool> {
         self.ends(with: values)
     }

     public func equals<C: Collection<QueryString>>(any values: C) -> MetadataQuery.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .equalTo, values.first!) : .or(mdKey, .equalTo, values)
     }

     public func equals(any values: QueryString...) -> MetadataQuery.Predicate<Bool> {
         self.equals(any: values)
     }

     public func equalsNot<C: Collection<QueryString>>(_ values: C) -> MetadataQuery.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .notEqualTo, values.first!) : .or(mdKey, .notEqualTo, values)
     }

     public func equalsNot(_ values: QueryString...) -> MetadataQuery.Predicate<Bool> {
         self.equalsNot(values)
     }

     public static func == (_ lhs: MetadataQuery.Predicate<T>, _ rhs: QueryString) -> MetadataQuery.Predicate<Bool> {
         .comparison(lhs.mdKey, .equalTo, rhs)
     }

     public static func == <C: Collection<QueryString>>(_ lhs: MetadataQuery.Predicate<T>, _ rhs: C) -> MetadataQuery.Predicate<Bool> {
         .or(lhs.mdKey, .equalTo, Array(rhs))
     }

     public static func != (_ lhs: MetadataQuery.Predicate<T>, _ rhs: QueryString) -> MetadataQuery.Predicate<Bool> {
         .comparison(lhs.mdKey, .notEqualTo, rhs)
     }

     public static func != <C: Collection<QueryString>>(_ lhs: MetadataQuery.Predicate<T>, _ rhs: C) -> MetadataQuery.Predicate<Bool> {
         .and(lhs.mdKey, .notEqualTo, Array(rhs))
     }

     public static func *== (_ lhs: MetadataQuery.Predicate<T>, _ rhs: QueryString) -> MetadataQuery.Predicate<Bool> {
         .comparison(lhs.mdKey, .beginsWith, rhs)
     }

     public static func *== <C: Collection<QueryString>>(_ lhs: MetadataQuery.Predicate<T>, _ rhs: C) -> MetadataQuery.Predicate<Bool> {
         .or(lhs.mdKey, .beginsWith, Array(rhs))
     }

     public static func *=* (_ lhs: MetadataQuery.Predicate<T>, _ rhs: QueryString) -> MetadataQuery.Predicate<Bool> {
         .comparison(lhs.mdKey, .contains, rhs)
     }

     public static func *=* <C: Collection<QueryString>>(_ lhs: MetadataQuery.Predicate<T>, _ rhs: C) -> MetadataQuery.Predicate<Bool> {
         .or(lhs.mdKey, .contains, Array(rhs))
     }

     public static func ==* (_ lhs: MetadataQuery.Predicate<T>, _ rhs: QueryString) -> MetadataQuery.Predicate<Bool> {
         .comparison(lhs.mdKey, .endsWith, rhs)
     }

     public static func ==* <C: Collection<QueryString>>(_ lhs: MetadataQuery.Predicate<T>, _ rhs: C) -> MetadataQuery.Predicate<Bool> {
             .or(lhs.mdKey, .endsWith, Array(rhs))
     }
 }

 public protocol QueryString { }
 extension String: QueryString { }

 public enum QString: QueryString {
     case c(String)
     case d(String)
     case w(String)
     case cd(String)
     case cw(String)
     case dw(String)
     case cdw(String)
     public var options: MetadataQuery.PredicateStringOptions {
         switch self {
         case .c( _): return .c
         case .d( _): return .d
         case .w( _): return .w
         case .cd( _): return .cd
         case .cw( _): return .cw
         case .dw( _): return .dw
         case .cdw( _): return .cdw
         }
     }
     public var value: String {
         switch self {
         case .c(let value), .d(let value), .w(let value), .cd(let value), .cw(let value), .dw(let value), .cdw(let value):
             return value
         }
     }
 }

 extension QueryString where Self == String {
     static func c(_ value: String) -> QString {
         QString.c(value)
     }
     static func d(_ value: String) -> QString {
         QString.d(value)
     }
     static func w(_ value: String) -> QString {
         QString.w(value)
     }
     static func cd(_ value: String) -> QString {
         QString.cd(value)
     }
     static func cw(_ value: String) -> QString {
         QString.cw(value)
     }
     static func dw(_ value: String) -> QString {
         QString.dw(value)
     }
     static func cdw(_ value: String) -> QString {
         QString.cdw(value)
     }
 }
  */

/*
 public enum QueryStringOption {
     case c(String)
     case d(String)
     case w(String)
     case cd(String)
     case cw(String)
     case dw(String)
     case cdw(String)
     var value: String {
         switch self {
         case .c(let value), .d(let value), .w(let value), .cd(let value), .cw(let value), .dw(let value), .cdw(let value):
             return value
         }
     }
     var options: MetadataQuery.PredicateStringOptions {
         switch self {
         case .c(_): return .c
         case .d(_): return .d
         case .w(_): return .w
         case .cd(_): return .cd
         case .cw(_): return .cw
         case .dw(_): return .dw
         case .cdw(_): return .cdw
         }
     }

     static func caseSensitive(_ string: String) -> QueryStringOption {
         return .c(string)
     }

     static func diacriticSensitive(_ string: String) -> QueryStringOption {
         return .d(string)
     }

     static func wordBased(_ string: String) -> QueryStringOption {
         return .w(string)
     }
 }
 */


/*
 extension MetadataQuery.Predicate where T: Equatable {
     /// Checks if an element equals a given value.
     public static func == (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool>  {
         .comparison(lhs.mdKey, .equalTo, rhs)
     }

     /// Checks if an element doesn't equal a given value.
     public static func != (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
         .comparison(lhs.mdKey, .notEqualTo, rhs)
     }
 }
  */


/*
  public func fileTypes(_ types: FileType...) -> MetadataQuery.Predicate<Bool> {
     return self.fileTypes(types)
 }

  public func fileTypes(_ types: [FileType]) -> MetadataQuery.Predicate<Bool> {
     let keyPath: PartialKeyPath<MetadataItem> = \.fileType
     if types.count == 1, let identifier = types.first?.identifier {
         return .comparison(keyPath.mdItemKey, .equalTo, identifier)
     } else {
         return .or(keyPath.mdItemKey,.equalTo, types.compactMap({$0.identifier}))
     }
 }
 */
