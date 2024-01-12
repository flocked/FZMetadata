//
//  MetadataQueryNew+Predicate.swift
//
//
//  Created by Florian Zand on 21.04.23.
//

import Foundation
import FZSwiftUtils
import UniformTypeIdentifiers


extension NSPredicate {
    typealias ItemNew = MetadataQueryNew.Predicate<MetadataItem>
    typealias BoolExpressionNew = MetadataQueryNew.Predicate<Swift.Bool>

    convenience init?(metadataExpression: (ItemNew) -> (BoolExpressionNew)) {
        guard let predicateFormat = metadataExpression(.root).predicate?.predicateFormat else { return nil }
        self.init(format: predicateFormat)
    }
}
 

public extension MetadataQueryNew {
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

        static var root: MetadataQueryNew.Predicate<MetadataItem> {
            .init("Root")
        }

        let mdKey: String

        let predicate: NSPredicate?

        /// All mdKeys used for the predicate.
        var mdKeys: [String] {
            self.predicate?.predicateFormat.matches(regex: #"\bkMDItem[a-zA-Z]*\b"#).compactMap(\.string).uniqued() ?? []
        }

        /// All attributes used for the predicate.
        var attributes: [MetadataItem.Attribute] {
            mdKeys.compactMap { MetadataItem.Attribute(rawValue: $0) }
        }

        /// Returns the metadata attribute for the specified `MetadataItem` keypath.
        public subscript(dynamicMember member: KeyPath<MetadataItem, Bool?>) -> MetadataQueryNew.Predicate<Bool> where T == MetadataItem {
            .comparison(member.mdItemKey, .equalTo, true)
        }

        /// Returns the metadata attribute for the specified `MetadataItem` keypath.
        public subscript<V>(dynamicMember member: KeyPath<MetadataItem, V>) -> MetadataQueryNew.Predicate<V> where T == MetadataItem {
            .init(member.mdItemKey)
        }

        static func comparison(_ mdKey: String, _ type: ComparisonOperator = .equalTo, _ value: Any, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
            .init(PredicateBuilder.comparison(mdKey, type, value, options))
        }

        static func between(_ mdKey: String, _ value: Any) -> MetadataQueryNew.Predicate<Bool> {
            .init(PredicateBuilder.between(mdKey, value: value))
        }

        static func between(_ mdKey: String, values: [Any]) -> MetadataQueryNew.Predicate<Bool> {
            .init(PredicateBuilder.between(mdKey, values: values))
        }

        static func and(_ predicates: [MetadataQueryNew.Predicate<Bool>]) -> MetadataQueryNew.Predicate<Bool> {
            .init(NSCompoundPredicate(and: predicates.compactMap(\.predicate)))
        }

        static func or(_ predicates: [MetadataQueryNew.Predicate<Bool>]) -> MetadataQueryNew.Predicate<Bool> {
            .init(NSCompoundPredicate(or: predicates.compactMap(\.predicate)))
        }

        static func not(_ predicate: MetadataQueryNew.Predicate<Bool>) -> MetadataQueryNew.Predicate<Bool> {
            .init(NSCompoundPredicate(not: predicate.predicate!))
        }

        static func and(_ mdKey: String, _: ComparisonOperator = .equalTo, _ values: [Any], _ options: [MetadataQueryNew.PredicateStringOptions] = [[]]) -> MetadataQueryNew.Predicate<Bool> {
            .init(PredicateBuilder.comparisonAnd(mdKey, .equalTo, values, options))
        }

        static func or(_ mdKey: String, _: ComparisonOperator = .equalTo, _ values: [Any], _ options: [MetadataQueryNew.PredicateStringOptions] = [[]]) -> MetadataQueryNew.Predicate<Bool> {
            .init(PredicateBuilder.comparisonOr(mdKey, .equalTo, values, options))
        }
    }
}

// MARK: MetadataItem

public extension MetadataQueryNew.Predicate where T == MetadataItem {
    /// The item is either a file, directory, volume or alias file.
    var any: MetadataQueryNew.Predicate<String> {
        .init("*")
    }

    /// Checks if an item is a file.
    var isFile: MetadataQueryNew.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.data")
    }

    /// Checks if an item is a directory.
    var isDirectory: MetadataQueryNew.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.folder")
    }

    var isItem: MetadataQueryNew.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.item")
    }

    /// Checks if an item is a volume.
    var isVolume: MetadataQueryNew.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.volume")
    }

    /// Checks if an item is a alias file.
    var isAlias: MetadataQueryNew.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "com.apple.alias-file")
    }

    /*
      public func fileTypes(_ types: FileType...) -> MetadataQueryNew.Predicate<Bool> {
         return self.fileTypes(types)
     }

      public func fileTypes(_ types: [FileType]) -> MetadataQueryNew.Predicate<Bool> {
         let keyPath: PartialKeyPath<MetadataItem> = \.fileType
         if types.count == 1, let identifier = types.first?.identifier {
             return .comparison(keyPath.mdItemKey, .equalTo, identifier)
         } else {
             return .or(keyPath.mdItemKey,.equalTo, types.compactMap({$0.identifier}))
         }
     }
     */
}

// MARK: Bool

public extension MetadataQueryNew.Predicate where T == Bool {
    static prefix func ! (_ lhs: Self) -> MetadataQueryNew.Predicate<Bool> {
        .not(lhs)
    }

    static func && (_ lhs: Self, _ rhs: Self) -> MetadataQueryNew.Predicate<Bool> {
        .and([lhs, rhs])
    }

    static func || (_ lhs: Self, _ rhs: Self) -> MetadataQueryNew.Predicate<Bool> {
        .or([lhs, rhs])
    }
}

// MARK: Equatable

extension MetadataQueryNew.Predicate where T: OptionalProtocol, T.Wrapped: QueryEquatable {}

/*
 extension MetadataQueryNew.Predicate where T: Equatable {
     /// Checks if an element equals a given value.
     public static func == (_ lhs: Self, _ rhs: T) -> MetadataQueryNew.Predicate<Bool>  {
         .comparison(lhs.mdKey, .equalTo, rhs)
     }

     /// Checks if an element doesn't equal a given value.
     public static func != (_ lhs: Self, _ rhs: T) -> MetadataQueryNew.Predicate<Bool> {
         .comparison(lhs.mdKey, .notEqualTo, rhs)
     }
 }
  */

public extension MetadataQueryNew.Predicate where T: QueryEquatable {
    /// Checks if an element isn't nil.
    var isNotNil: MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .like, "*")
    }

    /// Checks if an element is nil.
    var isNil: MetadataQueryNew.Predicate<Bool> {
        .not(isNotNil)
    }

    /// Checks if an element equals a given value.
    static func == (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQueryNew.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs.mdKey, .equalTo, rhs)
        } else {
            let isNotNil: MetadataQueryNew.Predicate<Bool> = .comparison(lhs.mdKey, .like, "*")
            return .not(isNotNil)
        }
    }

    /// Checks if an element doesn't equal a given value.
    static func != (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQueryNew.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs.mdKey, .notEqualTo, rhs)
        } else {
            return .comparison(lhs.mdKey, .like, "*")
        }
    }

    /// Checks if an element equals any given values.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == T {
        .or(lhs.mdKey, .equalTo, Array(rhs))
    }

    /// Checks if an element doesn't equal given values.
    static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == T {
        .and(lhs.mdKey, .notEqualTo, Array(rhs))
    }

    /// Checks if an element equals any given values.
    func `in`<C>(_ collection: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == T {
        .or(mdKey, .equalTo, Array(collection))
    }
}

// MARK: FileType

public extension MetadataQueryNew.Predicate where T: QueryFileType {
    static func == (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQueryNew.Predicate<Bool> where T: OptionalProtocol, T.Wrapped == FileType {
        .comparison(lhs.mdKey, .equalTo, rhs.identifier!)
    }

    static func != (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQueryNew.Predicate<Bool> where T: OptionalProtocol, T.Wrapped == FileType {
        .comparison(lhs.mdKey, .notEqualTo, rhs.identifier!)
    }

    /// Checks if an element equals any given values.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == T, T == FileType {
        .or(lhs.mdKey, .equalTo, rhs.compactMap(\.identifier))
    }

    /// Checks if an element equals any given values.
    static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == T, T == FileType {
        .and(lhs.mdKey, .notEqualTo, rhs.compactMap(\.identifier))
    }
}

// MARK: Comparable

public extension MetadataQueryNew.Predicate where T: QueryComparable {
    /// Checks if an element is greater than a given value.
    static func > (_ lhs: Self, _ rhs: T) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .greaterThan, rhs)
    }

    /// Checks if an element is greater than or equal to given value.
    static func >= (_ lhs: Self, _ rhs: T) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .greaterThanOrEqualTo, rhs)
    }

    /// Checks if an element is less than a given value.
    static func < (_ lhs: Self, _ rhs: T) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .lessThan, rhs)
    }

    /// Checks if an element is less than or equal to given value.
    static func <= (_ lhs: Self, _ rhs: T) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .lessThanOrEqualTo, rhs)
    }

    /// Checks if an element is between a given range.
    func between(_ range: Range<T>) -> MetadataQueryNew.Predicate<Bool> {
        .between(mdKey, range)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: Range<T>) -> MetadataQueryNew.Predicate<Bool> {
        .between(lhs.mdKey, rhs)
    }

    /// Checks if an element is between a given range.
    func between(_ range: ClosedRange<T>) -> MetadataQueryNew.Predicate<Bool> {
        .between(mdKey, range)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: ClosedRange<T>) -> MetadataQueryNew.Predicate<Bool> {
        .between(lhs.mdKey, rhs)
    }

    /// Checks if an element is between any given range.
    func between<C>(any ranges: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(mdKey, values: Array(ranges))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(lhs.mdKey, values: Array(rhs))
    }

    /// Checks if an element is between any given range.
    func between<C>(any ranges: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(mdKey, values: Array(ranges))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(lhs.mdKey, values: Array(rhs))
    }
}

// MARK: Date

public extension MetadataQueryNew.Predicate where T: QueryDate {
    /// Checks if a date is now.
    var isNow: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .now, mdKey: mdKey))
    }

    /// Checks if a date is this hour.
    var isThisHour: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .this(.hour), mdKey: mdKey))
    }

    /// Checks if a date is today.
    var isToday: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .today, mdKey: mdKey))
    }

    /// Checks if a date was yesterday.
    var isYesterday: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .yesterday, mdKey: mdKey))
    }

    /// Checks if a date is the same day as a given date.
    func isSameDay(as date: Date) -> MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .same(.day, date), mdKey: mdKey))
    }

    /// Checks if a date is this week.
    var isThisWeek: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .this(.weekOfYear), mdKey: mdKey))
    }

    /// Checks if a date is last week.
    var isLastWeek: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .last(1, .weekOfYear), mdKey: mdKey))
    }

    /// Checks if a date is the same week as a given date.
    func isSameWeek(as date: Date) -> MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .same(.weekOfYear, date), mdKey: mdKey))
    }

    /// Checks if a date is this month.
    var isThisMonth: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .this(.month), mdKey: mdKey))
    }

    /// Checks if a date is last month.
    var isLastMonth: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .last(1, .month), mdKey: mdKey))
    }

    /// Checks if a date is the same month as a given date.
    func isSameMonth(as date: Date) -> MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .same(.month, date), mdKey: mdKey))
    }

    /// Checks if a date is this year.
    var isThisYear: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .this(.year), mdKey: mdKey))
    }

    /// Checks if a date is last year.
    var isLastYear: MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .last(1, .year), mdKey: mdKey))
    }

    /// Checks if a date is the same year as a given date.
    func isSameYear(as date: Date) -> MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .same(.year, date), mdKey: mdKey))
    }

    /// Checks if a date is before a given date .
    func isBefore(_ date: Date) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .lessThan, date)
    }

    /// Checks if a date is after a given date .
    func isAfter(_ date: Date) -> MetadataQueryNew.Predicate<Bool> {
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
    func this(_ unit: Calendar.Component) -> MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .this(unit), mdKey: mdKey))
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
    func within(_ amout: Int, _ unit: Calendar.Component) -> MetadataQueryNew.Predicate<Bool> {
        .init(query(for: .last(amout, unit), mdKey: mdKey))
    }

    /// Checks if a date is between the specified date interval.
    func between(_ interval: DateInterval) -> MetadataQueryNew.Predicate<Bool> {
        .between(mdKey, [interval.start, interval.end])
    }

    /*
     /// Checks if a date is last week.
      public var isWeekday:  MetadataQueryNew.Predicate<Bool> {
          .init(query(for: .last(1, .year), mdKey: mdKey))
      }

     /// Checks if a date is last week.
      public var isWeekend:  MetadataQueryNew.Predicate<Bool> {
          .init(query(for: .last(1, .year), mdKey: mdKey))
      }
      */

    internal func query(for queryDate: QueryDateRange, mdKey: String) -> NSPredicate {
        PredicateBuilder.between(mdKey, values: queryDate.values)
    }
}

// MARK: UTType

@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
public extension MetadataQueryNew.Predicate where T: QueryUTType {
    /// Checks iif the content type is a subtype of a given type.
    func subtype(of type: UTType) -> MetadataQueryNew.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, type.identifier)
    }

    /// Checks iif the content type is a subtype of any given type.
    func subtype<C: Collection<UTType>>(of anyTypes: C) -> MetadataQueryNew.Predicate<Bool> {
        .or("kMDItemContentTypeTree", .equalTo, Array(anyTypes))
    }

    /// Checks iif the content type is equal to a given type.
    static func == (_: Self, _ rhs: UTType) -> MetadataQueryNew.Predicate<Bool> {
        .comparison("kMDItemContentType", .equalTo, rhs.identifier)
    }

    /// Checks iif the content type is equal to any given type.
    static func == <C: Collection<UTType>>(_: Self, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> {
        .or("kMDItemContentType", .equalTo, Array(rhs))
    }
}

// MARK: String

public extension MetadataQueryNew.Predicate where T: QueryString {
    /**
     Checks if a string contains a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    func contains(_ value: String, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .contains, value, options)
    }

    /**
     Checks if a string contains any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    func contains<C: Collection<String>>(any values: C, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .or(mdKey, .contains, Array(values), [options])
    }

    /**
     Checks if a string begins with a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    func begins(with value: String, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .beginsWith, value, options)
    }

    /**
     Checks if a string begins with any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    func begins<C: Collection<String>>(withAny values: C, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .or(mdKey, .beginsWith, Array(values), [options])
    }

    /**
     Checks if a string ends with a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    func ends(with value: String, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .endsWith, value, options)
    }

    /**
     Checks if a string ends with any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    func ends<C: Collection<String>>(withAny values: C, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .or(mdKey, .endsWith, Array(values), [options])
    }

    /**
     Checks if a string equals to a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    func equals(_ value: String, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .equalTo, value, options)
    }

    /**
     Checks if a string equals to any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    func equals<C: Collection<String>>(any values: C, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .or(mdKey, .equalTo, Array(values), [options])
    }

    /**
     Checks if a string doesn't equal to a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    func equalsNot(_ value: String, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .notEqualTo, value, options)
    }

    /**
     Checks if a string doesn't equal to any of the given strings.

     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    func equalsNot<C: Collection<String>>(_ values: C, _ options: MetadataQueryNew.PredicateStringOptions = []) -> MetadataQueryNew.Predicate<Bool> {
        .or(mdKey, .notEqualTo, Array(values), [options])
    }

    /// Checks if a string begins with a given string.
    static func *== (_ lhs: MetadataQueryNew.Predicate<T>, _ value: String) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .beginsWith, value)
    }

    /// Checks if a string begins with any of the given strings.
    static func *== <C: Collection<String>>(_ lhs: MetadataQueryNew.Predicate<T>, _ values: C) -> MetadataQueryNew.Predicate<Bool> {
        .or(lhs.mdKey, .beginsWith, Array(values))
    }

    /// Checks if a string contains a given string.
    static func *=* (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: String) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .contains, rhs)
    }

    /// Checks if a string contains any of the given strings.
    static func *=* <C: Collection<String>>(_ lhs: MetadataQueryNew.Predicate<T>, _ values: C) -> MetadataQueryNew.Predicate<Bool> {
        .or(lhs.mdKey, .contains, Array(values))
    }

    /// Checks if a string ends with a given string.
    static func ==* (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: String) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .endsWith, rhs)
    }

    /// Checks if a string ends with any of the given strings.
    static func ==* <C: Collection<String>>(_ lhs: MetadataQueryNew.Predicate<T>, _ values: C) -> MetadataQueryNew.Predicate<Bool> {
        .or(lhs.mdKey, .endsWith, Array(values))
    }
}

// MARK: String

extension MetadataQueryNew.Predicate where T: QueryFileType {}

/*
 extension MetadataQueryNew.Predicate where T: QueryString {
     public func begins<C: Collection<QueryString>>(with values: C) -> MetadataQueryNew.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .beginsWith, values.first!) : .or(mdKey, .beginsWith, values)
     }

     public func begins(with values: QueryString...) -> MetadataQueryNew.Predicate<Bool> {
         self.begins(with: values)
     }

     public func contains<C: Collection<QueryString>>(_ values: C) -> MetadataQueryNew.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .contains, values.first!) : .or(mdKey, .contains, values)
     }

     public func contains(_ values: QueryString...) -> MetadataQueryNew.Predicate<Bool> {
         self.contains(values)
     }

     public func ends<C: Collection<QueryString>>(with values: C) -> MetadataQueryNew.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .endsWith, values.first!) : .or(mdKey, .endsWith, values)
     }

     public func ends(with values: QueryString...) -> MetadataQueryNew.Predicate<Bool> {
         self.ends(with: values)
     }

     public func equals<C: Collection<QueryString>>(any values: C) -> MetadataQueryNew.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .equalTo, values.first!) : .or(mdKey, .equalTo, values)
     }

     public func equals(any values: QueryString...) -> MetadataQueryNew.Predicate<Bool> {
         self.equals(any: values)
     }

     public func equalsNot<C: Collection<QueryString>>(_ values: C) -> MetadataQueryNew.Predicate<Bool> {
         let values = Array(values)
         return (values.count == 1) ? .comparison(mdKey, .notEqualTo, values.first!) : .or(mdKey, .notEqualTo, values)
     }

     public func equalsNot(_ values: QueryString...) -> MetadataQueryNew.Predicate<Bool> {
         self.equalsNot(values)
     }

     public static func == (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: QueryString) -> MetadataQueryNew.Predicate<Bool> {
         .comparison(lhs.mdKey, .equalTo, rhs)
     }

     public static func == <C: Collection<QueryString>>(_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> {
         .or(lhs.mdKey, .equalTo, Array(rhs))
     }

     public static func != (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: QueryString) -> MetadataQueryNew.Predicate<Bool> {
         .comparison(lhs.mdKey, .notEqualTo, rhs)
     }

     public static func != <C: Collection<QueryString>>(_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> {
         .and(lhs.mdKey, .notEqualTo, Array(rhs))
     }

     public static func *== (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: QueryString) -> MetadataQueryNew.Predicate<Bool> {
         .comparison(lhs.mdKey, .beginsWith, rhs)
     }

     public static func *== <C: Collection<QueryString>>(_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> {
         .or(lhs.mdKey, .beginsWith, Array(rhs))
     }

     public static func *=* (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: QueryString) -> MetadataQueryNew.Predicate<Bool> {
         .comparison(lhs.mdKey, .contains, rhs)
     }

     public static func *=* <C: Collection<QueryString>>(_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> {
         .or(lhs.mdKey, .contains, Array(rhs))
     }

     public static func ==* (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: QueryString) -> MetadataQueryNew.Predicate<Bool> {
         .comparison(lhs.mdKey, .endsWith, rhs)
     }

     public static func ==* <C: Collection<QueryString>>(_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: C) -> MetadataQueryNew.Predicate<Bool> {
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
     public var options: MetadataQueryNew.PredicateStringOptions {
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
     var options: MetadataQueryNew.PredicateStringOptions {
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

// MARK: Collection

public extension MetadataQueryNew.Predicate where T: QueryCollection {
    /// Checks if the collection contains the given value.
    func contains(_ value: T.Element) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .equalTo, value)
    }

    /// Checks if the collection doesn't contain the given value.
    func containsNot(_ value: T.Element) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(mdKey, .notEqualTo, value)
    }

    /// Checks if the collection contains any of the given elements.
    func contains<U: Sequence>(any collection: U) -> MetadataQueryNew.Predicate<Bool> where U.Element == T.Element {
        .or(mdKey, .equalTo, Array(collection))
    }

    /// Checks if the collection doesn't contain any of the given elements.
    func containsNot<U: Sequence>(any collection: U) -> MetadataQueryNew.Predicate<Bool> where U.Element == T.Element {
        .and(mdKey, .notEqualTo, Array(collection))
    }

    /// Checks if the collection contains the given value.
    static func == (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: T.Element) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .equalTo, rhs)
    }

    /// Checks if the collection doesn't contain the given value.
    static func != (_ lhs: MetadataQueryNew.Predicate<T>, _ rhs: T.Element) -> MetadataQueryNew.Predicate<Bool> {
        .comparison(lhs.mdKey, .notEqualTo, rhs)
    }
}

// MARK: PredicateBuilder

extension MetadataQueryNew.Predicate {
    enum PredicateBuilder {
        static func comparisonAnd(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ options: [MetadataQueryNew.PredicateStringOptions] = []) -> NSPredicate {
            let predicates = values.enumerated().enumerated().compactMap { comparison(mdKey, type, $0.element, ($0.offset < options.count) ? options[$0.offset] : options.last ?? []) }
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(and: predicates)
        }

        static func comparisonOr(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ options: [MetadataQueryNew.PredicateStringOptions] = []) -> NSPredicate {
            let predicates = values.enumerated().enumerated().compactMap { comparison(mdKey, type, $0.element, ($0.offset < options.count) ? options[$0.offset] : options.last ?? []) }
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(or: predicates)
        }

        static func comparison(_ mdKey: String, _ type: ComparisonOperator, _ value: Any, _ options: MetadataQueryNew.PredicateStringOptions = []) -> NSPredicate {
            var value = value
            switch (mdKey, value) {
            case let (_, value as String):
                return string(mdKey, type, value, options)
            case let (_, value as CGSize):
                return size(mdKey, type, value)
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

        static func between(_ mdKey: String, value: Any) -> NSPredicate {
            var value = value
            switch value {
            case let _value as (any AnyRange):
                value = [_value.lowerBound, _value.upperBound]
            default: break
            }
            let _value = value as! [Any]
            let predicates = [comparison(mdKey, .greaterThanOrEqualTo, _value[0]), comparison(mdKey, .lessThanOrEqualTo, _value[1])]
            return NSCompoundPredicate(and: predicates)
        }

        static func between(_ mdKey: String, values: [Any]) -> NSPredicate {
            let predicates = values.compactMap { between(mdKey, value: $0) }
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(or: predicates)
        }

        static func size(_ mdKey: String, _ type: ComparisonOperator, _ value: CGSize) -> NSPredicate {
            let widthMDKey = mdKey.replacingOccurrences(of: "Size", with: "Width")
            let heightMDKey = mdKey.replacingOccurrences(of: "Size", with: "Height")
            let predicates = [comparison(widthMDKey, type, [value.width]), comparison(heightMDKey, type, [value.height])]
            return NSCompoundPredicate(and: predicates)
        }

        /*
         static func queryString(_ mdKey: String, _ type: ComparisonOperator, _ queryString: QueryStringOption) -> NSPredicate {
                 return string(mdKey, type, queryString.value, queryString.options)
         }
          */

        static func string(_ mdKey: String, _ type: ComparisonOperator, _ value: String, _ options: MetadataQueryNew.PredicateStringOptions? = []) -> NSPredicate {
            var mdKey = mdKey
            var value = value
            var options = options ?? []
            options.insert(MetadataQueryNew.PredicateStringOptions.extract(&value))
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
    }
}
