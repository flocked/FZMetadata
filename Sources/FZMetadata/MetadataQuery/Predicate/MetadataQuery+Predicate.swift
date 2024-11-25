//
//  MetadataQuery+Predicate.swift
//
//
//  Created by Florian Zand on 21.04.23.
//

import Foundation
import FZSwiftUtils
import UniformTypeIdentifiers

public extension MetadataQuery {
    /**
     A predicate for filtering the results of a query.

     ### Operators
     Predicates can be defined by comparing MetadataItem properties to values using operators and functions.

     Depending on the property type there are different operators and functions available:

     ## General
     - ``isFile``
     - ``isFolder``
     - ``isAlias``
     - ``isVolume``
     - ``any``  (either file, directory, alias or volume)

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

     ```swift
     // fileName is "MyFile.doc" and creator isn't "Florian"
     query.predicate = { $0.fileName == "MyFile.doc" && $0.creater != "Florian"}

     // fileExtension is either "mp4", "mov" or "ts"
     query.predicate = { $0.fileExtension == ["mp4", "mov", "ts"] }

     // fileExtension isn't "mp3", "wav" and aiff
     query.predicate = { $0.fileExtension != ["mp3", "wav", "aiff"] }
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
     - ``starts(with:)`` OR  `*== String`
     - ``ends(with:)`` OR  `==* String`
     - ``contains(_:)-5iysw`` OR `*=* String`

     ```swift
     // fileName ends with ".doc"
     { $0.fileName.ends(with: ".doc") }
     { $0.fileName ==*  ".doc" }

     // fileName contains "MyFile"
     { $0.fileName.contains("MyFile") }
     { $0.fileName *=*  "MyFile" }
     ```

     By default string predicates are case- and diacritic-insensitive.

     Use ``caseSensitive`` for case-sensitive, ``diacriticSensitive``, for diacritic-sensitve and ``wordBased`` for word-based string comparsion.

     ```swift
     // case-sensitive
     { $0.fileName.caseSensitive.begins(with: "MyF") }

     // case- and diacritic-sensitive
     { $0.fileName.caseSensitive.diacriticSensitive.begins(with: "MyF") }
     ```

     ## Date
    
     You can either compare a date to another date, or use ``DateValue``.
     
     - ``DateValue/now``.
     - ``DateValue/today``
     - ``DateValue/yesterday``
     - ``DateValue/sameDay(_:)``
     - ``DateValue/thisWeek``
     - ``DateValue/lastWeek``
     - ``DateValue/sameWeek(_:)``
     - ``DateValue/thisMonth``
     - ``DateValue/lastMonth``
     - ``DateValue/sameMonth(_:)``
     - ``DateValue/thisYear``
     - ``DateValue/lastYear``
     - ``DateValue/sameYear(_:)``
     - ``DateValue/within(_:_:)``
     - ``DateValue/this(_:)``

     ```swift
     // is today
     { $0.creationDate == .today }

     // is same week as otherDate
     { $0.creationDate == .sameWeek(otherDate) }

     // is within 4 weeks
     { $0.creationDate == .within(4, .week) }
     ```

     ## Collection
     - ``contains(_:)-8fg9``  OR `== Element`
     - ``containsNot(_:)``  OR `!= Element`
     - ``contains(any:)-2ysd3``
     - ``containsNot(any:)``

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
    struct Predicate<T>: _Predicate {
        typealias ComparisonOperator = NSComparisonPredicate.Operator

        init(_ mdKey: String) {
            self.mdKeys = [mdKey]
            self.predicate = nil
        }

        init(_ predicate: NSPredicate, _ predicates: [_Predicate] = []) {
            self.mdKeys = predicates.flatMap({$0.mdKeys}).uniqued()
            self.predicate = predicate
        }

        var mdKeys: [String] = []
        let predicate: NSPredicate?
        var stringOptions: PredicateStringOptions = []
        var valueConverter: PredicateValueConverter? = nil
       
        /// All attributes used by the predicate.
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
            .init(NSCompoundPredicate(and: predicates.compactMap(\.predicate)), predicates)
        }

        static func or(_ predicates: [MetadataQuery.Predicate<Bool>]) -> MetadataQuery.Predicate<Bool> {
            .init(NSCompoundPredicate(or: predicates.compactMap(\.predicate)), predicates)
        }

        static func not(_ predicate: MetadataQuery.Predicate<Bool>) -> MetadataQuery.Predicate<Bool> {
            .init(NSCompoundPredicate(not: predicate.predicate!), [predicate])
        }
        
        static func comparison(_ predicate: _Predicate, _ type: ComparisonOperator = .equalTo, _ value: Any) -> MetadataQuery.Predicate<Bool> {
            .init(self.predicate(predicate.mdKeys.first!, type, value, predicate.stringOptions, predicate.valueConverter), [predicate])
        }
        
        static func comparisonAnd(_ predicate: _Predicate, _ comparisonOperator: ComparisonOperator = .equalTo, _ values: [Any]) -> MetadataQuery.Predicate<Bool> {
            .init(predicateAnd(predicate.mdKeys.first!, comparisonOperator, values, predicate.stringOptions, predicate.valueConverter), [predicate])
        }
        
        static func comparisonOr(_ predicate: _Predicate, _ comparisonOperator: ComparisonOperator = .equalTo, _ values: [Any]) -> MetadataQuery.Predicate<Bool> {
            .init(predicateOr(predicate.mdKeys.first!, comparisonOperator, values, predicate.stringOptions, predicate.valueConverter), [predicate])
        }
        
        static func between(_ predicate: _Predicate, value1: Any, value2: Any) -> MetadataQuery.Predicate<Bool> {
            and([
                comparison(predicate, .greaterThanOrEqualTo, value1),
                comparison(predicate, .lessThanOrEqualTo, value2)])
        }
        
        static func between(_ predicate: _Predicate, values: [(Any, Any)]) -> MetadataQuery.Predicate<Bool> {
            or(values.compactMap({ between(predicate, value1: $0.0, value2: $0.1) }))
        }
        
        static var root: Predicate<MetadataItem> {
            .init("Root")
        }
    }
}

// MARK: General

public extension MetadataQuery.Predicate where T == MetadataItem {
    /// Matches for ``MetadataItem/Attribute/fileName`` and ``MetadataItem/Attribute/textContent``.
    var any: MetadataQuery.Predicate<String> {
        .init("*")
    }

    /// The item is a file.
    var isFile: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.data")
    }

    /// The item is a folder.
    var isFolder: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.folder")
    }

    /// The item is a volume.
    var isVolume: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.volume")
    }

    /// The item is an alias file.
    var isAlias: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "com.apple.alias-file")
    }
    
    internal var isItem: MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, "public.item")
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

    /// Checks if an element equals a given value.
    static func == (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs, .equalTo, rhs)
        } else {
            return .not(.comparison(lhs, .like, "*"))
        }
    }

    /// Checks if an element doesn't equal a given value.
    static func != (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs, .notEqualTo, rhs)
        } else {
            return .comparison(lhs, .like, "*")
        }
    }

    /// Checks if an element equals any given values.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .comparisonOr(lhs, .equalTo, Array(rhs))
    }

    /// Checks if an element doesn't equal given values.
    static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .comparisonAnd(lhs, .notEqualTo, Array(rhs))
    }

    /// Checks if an element equals any given values.
    func `in`<C>(_ collection: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .comparisonOr(self, .equalTo, Array(collection))
    }
}

// MARK: Comparable

public extension MetadataQuery.Predicate where T: QueryComparable {
    /// Checks if an element is greater than a given value.
    static func > (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs, .greaterThan, rhs)
    }

    /// Checks if an element is greater than or equal to given value.
    static func >= (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs, .greaterThanOrEqualTo, rhs)
    }

    /// Checks if an element is less than a given value.
    static func < (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs, .lessThan, rhs)
    }

    /// Checks if an element is less than or equal to given value.
    static func <= (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs, .lessThanOrEqualTo, rhs)
    }

    /// Checks if an element is between a given range.
    func isBetween(_ range: Range<T>) -> MetadataQuery.Predicate<Bool> {
        .between(self, value1: range.lowerBound, value2: range.upperBound)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: Range<T>) -> MetadataQuery.Predicate<Bool> {
        .between(lhs, value1: rhs.lowerBound, value2: rhs.upperBound)
    }

    /// Checks if an element is between a given range.
    func isBetween(_ range: ClosedRange<T>) -> MetadataQuery.Predicate<Bool> {
        .between(self, value1: range.lowerBound, value2: range.upperBound)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: ClosedRange<T>) -> MetadataQuery.Predicate<Bool> {
        .between(lhs, value1: rhs.lowerBound, value2: rhs.upperBound)
    }

    /// Checks if an element is between any given range.
    func isBetween<C>(any ranges: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(self, values: ranges.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(lhs, values: rhs.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    func isBetween<C>(any ranges: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(self, values: ranges.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(lhs, values: rhs.compactMap({($0.lowerBound, $0.upperBound)}))
    }
}

// MARK: Date

public extension MetadataQuery.Predicate where T: QueryDate {
    /// Checks if a date matches the specified date value.
    static func == (lhs: Self, rhs: DateValue) -> MetadataQuery.Predicate<Bool> {
        let values = rhs.values
        return .between(lhs, value1: values[0], value2: values[1])
    }
    
    /// Checks if a date is before the specified date.
    func isBefore(_ date: Date) -> MetadataQuery.Predicate<Bool> {
        .comparison(self, .lessThan, date)
    }
    
    /// Checks if a date is after the specified date.
    func isAfter(_ date: Date) -> MetadataQuery.Predicate<Bool> {
        .comparison(self, .greaterThan, date)
    }
    
    /// Checks if a date is between the specified date interval.
    func isBetween(_ interval: DateInterval) -> MetadataQuery.Predicate<Bool> {
        .between(self, value1: interval.start, value2: interval.end)
    }
    
    /// Checks if a date is between the specified date interval.
    static func == (lhs: Self, rhs: DateInterval) -> MetadataQuery.Predicate<Bool> {
        lhs.isBetween(rhs)
    }
    
    /*
    /// Checks if a date is now.
    var isNow: MetadataQuery.Predicate<Bool> {
        self == .now
    }
    
    /// Checks if a date is this hour.
    var isThisHour: MetadataQuery.Predicate<Bool> {
        self == .thisHour
    }
    
    /// Checks if a date is last hour.
    var isLastHour: MetadataQuery.Predicate<Bool> {
        self == .lastHour
    }
    
    /// Checks if a date is same hour as the specified date.
    func isSameHour(as date: Date) -> MetadataQuery.Predicate<Bool> {
        self == .sameHour(date)
    }
    
    /// Checks if a date is today.
    var today: MetadataQuery.Predicate<Bool> {
        self == .today
    }
    
    /// Checks if a date is yesterday.
    var yesterday: MetadataQuery.Predicate<Bool> {
        self == .yesterday
    }
    
    /// Checks if a date is same day as the specified date.
    func isSameDay(as date: Date) -> MetadataQuery.Predicate<Bool> {
        self == .sameDay(date)
    }
    
    var isThisWeek: MetadataQuery.Predicate<Bool> {
        self == .thisWeek
    }
    
    /// Checks if a date is last week.
    var isLastWeek: MetadataQuery.Predicate<Bool> {
        self == .lastWeek
    }
    
    /// Checks if a date is same week as the specified date.
    func isSameWeek(as date: Date) -> MetadataQuery.Predicate<Bool> {
        self == .sameWeek(date)
    }
    
    /// Checks if a date is this month.
    var isThisMonth: MetadataQuery.Predicate<Bool> {
        self == .thisMonth
    }
    
    /// Checks if a date is last month.
    var isLastMonth: MetadataQuery.Predicate<Bool> {
        self == .lastMonth
    }
    
    /// Checks if a date is same month as the specified date.
    func isSameMonth(as date: Date) -> MetadataQuery.Predicate<Bool> {
        self == .sameMonth(date)
    }
    
    /// Checks if a date is this year.
    var isThisYear: MetadataQuery.Predicate<Bool> {
        self == .thisYear
    }
    
    /// Checks if a date is last year.
    var isLastYear: MetadataQuery.Predicate<Bool> {
        self == .lastYear
    }
    
    /// Checks if a date is same year as the specified date.
    func isSameYear(as date: Date) -> MetadataQuery.Predicate<Bool> {
        self == .sameYear(date)
    }
    
    /**
     Checks if a date is within the last specified amount of  calendar units.
     
     Example:
     ```swift
     // creationDate is within the last 8 weeks.
     { $0.creationDate.isWithin(8, .week) }
     
     // creationDate is within the last 2 years.
     { $0.creationDate.isWithin(2, .year) }
     ```
     */
    func isWithin(_ amount: Int, _ unit: DateValue.DateComponent) -> MetadataQuery.Predicate<Bool> {
        self == .within(amount, unit)
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

    /// Checks if the content type is a subtype of any given type.
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
    /// Case-sensitive string comparison.
    var caseSensitive: Self {
        var predicate = self
        predicate.stringOptions.insert(.caseSensitive)
        return predicate
    }
    
    /// Diacritic-sensitive string comparison.
    var diacriticSensitive: Self {
        var predicate = self
        predicate.stringOptions.insert(.diacriticSensitive)
        return predicate
    }
    
    /// Word based string comparison.
    var wordBased: Self {
        var predicate = self
        predicate.stringOptions.insert(.wordBased)
        return predicate
    }
    
    /// Checks if a string contains the specified string.
    func contains(_ value: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(self, .contains, value)
    }

    /// Checks if a string contains any of the specified strings.
    func contains<C: Collection<String>>(any values: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(self, .contains, Array(values))
    }

    /// Checks if a string begins with the specified string.
    func starts(with value: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(self, .beginsWith, value)
    }

    /// Checks if a string begins with any of the specified strings.
    func starts<C: Collection<String>>(withAny values: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(self, .beginsWith, Array(values))
    }

    /// Checks if a string ends with the specified string.
    func ends(with value: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(self, .endsWith, value)
    }

    /// Checks if a string ends with any of the specified strings.
    func ends<C: Collection<String>>(withAny values: C) -> MetadataQuery.Predicate<Bool> {
        .comparisonOr(self, .endsWith, Array(values))
    }

    /// Checks if a string begins with a given string.
    static func *== (_ lhs: MetadataQuery.Predicate<T>, _ value: String) -> MetadataQuery.Predicate<Bool> {
        lhs.starts(with: value)
    }

    /// Checks if a string begins with any of the given strings.
    static func *== <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        lhs.starts(withAny: values)

    }

    /// Checks if a string contains a given string.
    static func *=* (_ lhs: MetadataQuery.Predicate<T>, _ value: String) -> MetadataQuery.Predicate<Bool> {
        lhs.contains(value)
    }

    /// Checks if a string contains any of the given strings.
    static func *=* <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        lhs.contains(any: values)
    }

    /// Checks if a string ends with a given string.
    static func ==* (_ lhs: MetadataQuery.Predicate<T>, _ value: String) -> MetadataQuery.Predicate<Bool> {
        lhs.ends(with: value)
    }

    /// Checks if a string ends with any of the given strings.
    static func ==* <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        lhs.ends(withAny: values)
    }
}

// MARK: Collection

public extension MetadataQuery.Predicate where T: QueryCollection {
    /// Checks if the collection contains the given value.
    func contains(_ value: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(self, .equalTo, value)
    }

    /// Checks if the collection doesn't contain the given value.
    func containsNot(_ value: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(self, .notEqualTo, value)
    }

    /// Checks if the collection contains any of the given elements.
    func contains<U: Sequence>(any collection: U) -> MetadataQuery.Predicate<Bool> where U.Element == T.Element {
        .comparisonOr(self, .equalTo, Array(collection))
    }

    /// Checks if the collection doesn't contain any of the given elements.
    func containsNot<U: Sequence>(any collection: U) -> MetadataQuery.Predicate<Bool> where U.Element == T.Element {
        .comparisonAnd(self, .notEqualTo, Array(collection))
    }

    /// Checks if the collection contains the given value.
    static func == (_ lhs: MetadataQuery.Predicate<T>, _ rhs: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs, .equalTo, rhs)
    }

    /// Checks if the collection doesn't contain the given value.
    static func != (_ lhs: MetadataQuery.Predicate<T>, _ rhs: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs, .notEqualTo, rhs)
    }
}

// MARK: DataSize

public extension MetadataQuery.Predicate where T == DataSize? {
    /// Bytes.
    var bytes: MetadataQuery.Predicate<Double?> {
        unit(.byte)
    }
    
    /// Kilobytes.
    var kilobytes: MetadataQuery.Predicate<Double?> {
        unit(.kilobyte)
    }
    
    /// Megabytes.
    var megabytes: MetadataQuery.Predicate<Double?> {
        unit(.megabyte)
    }
    
    /// Gigabytes.
    var gigabytes: MetadataQuery.Predicate<Double?> {
        unit(.gigabyte)
    }
    
    /// Terabytes.
    var terabytes: MetadataQuery.Predicate<Double?> {
        unit(.terabyte)
    }
    
    /// Petabytes.
    var petabytes: MetadataQuery.Predicate<Double?> {
        unit(.petabyte)
    }
    
    private func unit(_ unit: DataSize.Unit) -> MetadataQuery.Predicate<Double?> {
        var predicate: MetadataQuery.Predicate<Double?> = .init(mdKeys.first!)
        predicate.valueConverter = unit
        return predicate
    }
}

// MARK: TimeDuration

public extension MetadataQuery.Predicate where T == TimeDuration? {
    /// Seconds.
    var seconds: MetadataQuery.Predicate<Double?> {
        unit(.minute)
    }
    
    /// Minutes.
    var minutes: MetadataQuery.Predicate<Double?> {
        unit(.minute)
    }
    
    /// Hours.
    var hours: MetadataQuery.Predicate<Double?> {
        unit(.hour)
    }
    
    /// Days.
    var days: MetadataQuery.Predicate<Double?> {
        unit(.day)
    }
    
    /// weeks.
    var weeks: MetadataQuery.Predicate<Double?> {
        unit(.week)
    }
    
    /// Months.
    var months: MetadataQuery.Predicate<Double?> {
        unit(.month)
    }
    
    /// Years.
    var years: MetadataQuery.Predicate<Double?> {
        unit(.year)
    }
    
    private func unit(_ unit: TimeDuration.Unit) -> MetadataQuery.Predicate<Double?> {
        var predicate: MetadataQuery.Predicate<Double?> = .init(mdKeys.first!)
        predicate.valueConverter = unit
        return predicate
    }
}

// MARK: PredicateBuilder

extension MetadataQuery.Predicate {
    static func predicate(_ mdKey: String, _ type: ComparisonOperator, _ value: Any, _ options: MetadataQuery.PredicateStringOptions = [], _ converter: PredicateValueConverter? = nil) -> NSPredicate {
        var value = converter?.value(for: value) ?? value
        switch value {
        case let value as String:
            guard !value.hasPrefix("$time") else { break }
            return predicateString(mdKey, type, value, options)
        case let value as CGSize:
            return predicateSize(mdKey, type, value)
        case let rect as CGRect:
            value = [rect.origin.x, rect.origin.y, rect.width, rect.height]
        case let _value as (any QueryRawRepresentable):
            value = _value.rawValue
        default: break
        }
        let key = NSExpression(forKeyPath: mdKey)
        let valueEx = NSExpression(forConstantValue: value)
        return NSComparisonPredicate(leftExpression: key, rightExpression: valueEx, modifier: .direct, type: type)
    }
    
    static func predicateAnd(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ option: MetadataQuery.PredicateStringOptions = [], _ converter: PredicateValueConverter? = nil) -> NSPredicate {
        let predicates = values.enumerated().compactMap { predicate(mdKey, type, $0.element, option, converter) }
        return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(and: predicates)
    }

    static func predicateOr(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ option: MetadataQuery.PredicateStringOptions = [], _ converter: PredicateValueConverter? = nil) -> NSPredicate {
        let predicates = values.enumerated().compactMap { predicate(mdKey, type, $0.element, option, converter) }
        return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(or: predicates)
    }

    static func predicateSize(_ mdKey: String, _ type: ComparisonOperator, _ value: CGSize) -> NSPredicate {
        let widthMDKey = mdKey.replacingOccurrences(of: "Size", with: "Width")
        let heightMDKey = mdKey.replacingOccurrences(of: "Size", with: "Height")
        let predicates = [predicate(widthMDKey, type, [value.width]), predicate(heightMDKey, type, [value.height])]
        return NSCompoundPredicate(and: predicates)
    }
    
    static func predicateString(_ mdKey: String, _ type: ComparisonOperator, _ value: String, _ options: MetadataQuery.PredicateStringOptions = []) -> NSPredicate {
        let predicateString: String
        Swift.print("predicateString", value)
        switch (type, value) {
        case (_, "kMDItemFSExtension"):
            predicateString = "kMDItemFSName = '*.\(value)'\(options.string)"
        case (.contains, _):
            predicateString = "\(mdKey) = '*\(value)*'\(options.string)"
        case (.beginsWith, _):
            predicateString = "\(mdKey) = '\(value)*'\(options.string)"
        case (.endsWith, _):
            predicateString = "\(mdKey) = '*\(value)'\(options.string)"
        case (.notEqualTo, _):
            predicateString = "\(mdKey) != '\(value)'\(options.string)"
        default:
            predicateString = "\(mdKey) = '\(value)'\(options.string)"
        }
        #if os(macOS)
            return NSPredicate(fromMetadataQueryString: predicateString)!
        #else
            return NSPredicate(format: predicateString)
        #endif
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

protocol _Predicate {
    var mdKeys: [String] { get }
    var stringOptions: MetadataQuery.PredicateStringOptions { get }
    var valueConverter: PredicateValueConverter? { get }
}

extension String: _Predicate {
    var mdKey: String { self }
    var mdKeys: [String] { [self] }
    var stringOptions: MetadataQuery.PredicateStringOptions { return [] }
    var valueConverter: PredicateValueConverter? { return nil }
}

protocol PredicateValueConverter {
    func value(for value: Any) -> Any
}

extension TimeDuration.Unit: PredicateValueConverter {
    func value(for value: Any) -> Any {
        guard let value = value as? Double else { return value }
        let factor: Double = 60
        let conversionFactor = pow(factor, Double(rawValue - TimeDuration.Unit.second.rawValue))
        return value * conversionFactor
    }
}

extension DataSize.Unit: PredicateValueConverter {
    func value(for value: Any) -> Any {
        guard let value = value as? Double else { return value }
        switch self {
        case .byte: return Int(value)
        case .kilobyte: return DataSize.kilobytes(value).bytes
        case .megabyte: return DataSize.megabytes(value).bytes
        case .gigabyte: return DataSize.gigabytes(value).bytes
        case .terabyte: return DataSize.terabytes(value).bytes
        case .petabyte: return DataSize.petabytes(value).bytes
        case .exabyte: return DataSize.exabytes(value).bytes
        case .zettabyte: return DataSize.zettabytes(value).bytes
        case .yottabyte: return DataSize.yottabytes(value).bytes
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
        default:
            key = NSExpression(forKeyPath: "kMDItemContentTypeTree")
            type = .like
        }
        let value: NSExpression
        switch self {
        case .executable: value = NSExpression(format: "%i", 8)
        case .folder: value = NSExpression(format: "%i", 9)
        case .audio: value = NSExpression(format: "%i", 10)
        case .pdf: value = NSExpression(format: "%i", 11)
        case .image: value = NSExpression(format: "%i", 13)
        case .video: value = NSExpression(format: "%i", 7)
        case .presentation: value = NSExpression(format: "%i", 12)
        case let .unknown(oValue): value = NSExpression(format: "%@", oValue)
        default: value = NSExpression(format: "%@", identifier ?? "public.item")
        }

        let modifier: NSComparisonPredicate.Modifier
        switch self {
        case .application, .archive, .text, .document, .unknown:
            modifier = .any
        default:
            modifier = .direct
        }
        return NSComparisonPredicate(leftExpression: key, rightExpression: value, modifier: modifier, type: type)
    }
}
