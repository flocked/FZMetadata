//
//  MetadataQuery+PredicateComponent.swift
//  FZMetadata
//
//  Created by Florian Zand on 25.04.25.
//

import Foundation
import FZSwiftUtils
import UniformTypeIdentifiers

extension MetadataQuery {
    public struct PredicateComponent<T>: _Predicate {
        let mdKeys: [String]
        var stringOptions: PredicateStringOptions = []
        var valueConverter: PredicateValueConverter? = nil
        
        init(_ mdKey: String) {
            self.mdKeys = [mdKey]
        }
        
        init(_ mdKeys: [String], _ converter: PredicateValueConverter? = nil, _ stringOptions: PredicateStringOptions = []) {
            self.mdKeys = mdKeys
            self.valueConverter = converter
            self.stringOptions = stringOptions
        }
    }
}

public extension MetadataQuery.PredicateComponent where T: QueryEquatable {
    /// Checks if an element equals a given value.
    static func == (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.PredicateResult where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs, .equalTo, rhs)
        } else {
            return .not(.comparison(lhs, .like, "*"))
        }
    }

    /// Checks if an element doesn't equal a given value.
    static func != (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.PredicateResult where T: OptionalProtocol {
        if let rhs = rhs {
            return .comparison(lhs, .notEqualTo, rhs)
        } else {
            return .comparison(lhs, .like, "*")
        }
    }

    /// Checks if an element equals any given values.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == T {
        .comparisonOr(lhs, .equalTo, Array(rhs))
    }

    /// Checks if an element doesn't equal given values.
    static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == T {
        .comparisonAnd(lhs, .notEqualTo, Array(rhs))
    }

    /// Checks if an element equals any given values.
    func `in`<C>(_ collection: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == T {
        .comparisonOr(self, .equalTo, Array(collection))
    }
}

public extension MetadataQuery.PredicateComponent where T: QueryComparable {
    /// Checks if an element is greater than a given value.
    static func > (_ lhs: Self, _ rhs: T) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .greaterThan, rhs)
    }

    /// Checks if an element is greater than or equal to given value.
    static func >= (_ lhs: Self, _ rhs: T) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .greaterThanOrEqualTo, rhs)
    }

    /// Checks if an element is less than a given value.
    static func < (_ lhs: Self, _ rhs: T) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .lessThan, rhs)
    }

    /// Checks if an element is less than or equal to given value.
    static func <= (_ lhs: Self, _ rhs: T) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .lessThanOrEqualTo, rhs)
    }

    /// Checks if an element is between a given range.
    func isBetween(_ range: Range<T>) -> MetadataQuery.PredicateResult {
        .between(self, value1: range.lowerBound, value2: range.upperBound)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: Range<T>) -> MetadataQuery.PredicateResult {
        .between(lhs, value1: rhs.lowerBound, value2: rhs.upperBound)
    }

    /// Checks if an element is between a given range.
    func isBetween(_ range: ClosedRange<T>) -> MetadataQuery.PredicateResult {
        .between(self, value1: range.lowerBound, value2: range.upperBound)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: ClosedRange<T>) -> MetadataQuery.PredicateResult {
        .between(lhs, value1: rhs.lowerBound, value2: rhs.upperBound)
    }

    /// Checks if an element is between any given range.
    func isBetween<C>(any ranges: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == Range<T> {
        .between(self, values: ranges.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == Range<T> {
        .between(lhs, values: rhs.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    func isBetween<C>(any ranges: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == ClosedRange<T> {
        .between(self, values: ranges.compactMap({($0.lowerBound, $0.upperBound)}))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == ClosedRange<T> {
        .between(lhs, values: rhs.compactMap({($0.lowerBound, $0.upperBound)}))
    }
}

// MARK: Date

public extension MetadataQuery.PredicateComponent where T: QueryDate {
    /// Checks if a date is now.
    var isNow: MetadataQuery.PredicateResult {
        self == .now
    }
    
    /// Checks if a date is this Minute.
    var isThisMinute: MetadataQuery.PredicateResult {
        self == .thisMinute
    }
    
    /// Checks if a date is last minute.
    var isLastMinute: MetadataQuery.PredicateResult {
        self == .lastMinute
    }
    
    /// Checks if a date is this hour.
    var isThisHour: MetadataQuery.PredicateResult {
        self == .thisHour
    }
    
    /// Checks if a date is last hour.
    var isLastHour: MetadataQuery.PredicateResult {
        self == .lastHour
    }
    
    /// Checks if a date is same hour as the specified date.
    func isSameHour(as date: Date) -> MetadataQuery.PredicateResult {
        self == .sameHour(date)
    }
    
    /// Checks if a date is today.
    var isToday: MetadataQuery.PredicateResult {
        self == .today
    }
    
    /// Checks if a date is yesterday.
    var isYesterday: MetadataQuery.PredicateResult {
        self == .yesterday
    }
    
    /// Checks if a date is same day as the specified date.
    func isSameDay(as date: Date) -> MetadataQuery.PredicateResult {
        self == .sameDay(date)
    }
    
    /// Checks if a date is this week.
    var isThisWeek: MetadataQuery.PredicateResult {
        self == .thisWeek
    }
    
    /// Checks if a date is last week.
    var isLastWeek: MetadataQuery.PredicateResult {
        self == .lastWeek
    }
    
    /// Checks if a date is same week as the specified date.
    func isSameWeek(as date: Date) -> MetadataQuery.PredicateResult {
        self == .sameWeek(date)
    }
    
    /// Checks if a date is this month.
    var isThisMonth: MetadataQuery.PredicateResult {
        self == .thisMonth
    }
    
    /// Checks if a date is last month.
    var isLastMonth: MetadataQuery.PredicateResult {
        self == .lastMonth
    }
    
    /// Checks if a date is same month as the specified date.
    func isSameMonth(as date: Date) -> MetadataQuery.PredicateResult {
        self == .sameMonth(date)
    }
    
    /// Checks if a date is this year.
    var isThisYear: MetadataQuery.PredicateResult {
        self == .thisYear
    }
    
    /// Checks if a date is last year.
    var isLastYear: MetadataQuery.PredicateResult {
        self == .lastYear
    }
    
    /// Checks if a date is same year as the specified date.
    func isSameYear(as date: Date) -> MetadataQuery.PredicateResult {
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
    func isWithin(_ amount: Int, _ unit: DateComponent) -> MetadataQuery.PredicateResult {
        self == .within(amount, unit)
    }
    
    /// Checks if a date is before the specified date.
    func isBefore(_ date: Date) -> MetadataQuery.PredicateResult {
        .comparison(self, .lessThan, date)
    }
    
    /// Checks if a date is after the specified date.
    func isAfter(_ date: Date) -> MetadataQuery.PredicateResult {
        .comparison(self, .greaterThan, date)
    }
    
    /// Checks if a date is between the specified date interval.
    static func == (lhs: Self, rhs: DateInterval) -> MetadataQuery.PredicateResult {
        .between(lhs, value1: rhs.start, value2: rhs.end)
    }
    
    /// Checks if a date matches the specified date value.
    internal static func == (lhs: Self, rhs: DateValue) -> MetadataQuery.PredicateResult {
        let values = rhs.values
        return .between(lhs, value1: values[0], value2: values[1])
    }
}

// MARK: UTType

@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
public extension MetadataQuery.PredicateComponent where T: QueryUTType {
    /// Checks iif the content type is a subtype of a given type.
    func isSubtype(of type: UTType) -> MetadataQuery.PredicateResult {
        .comparison("kMDItemContentTypeTree", .equalTo, type.identifier)
    }

    /// Checks if the content type is a subtype of any given type.
    func isSubtype<C: Collection<UTType>>(of anyTypes: C) -> MetadataQuery.PredicateResult {
        .comparisonOr("kMDItemContentTypeTree", .equalTo, Array(anyTypes))
    }

    /// Checks iif the content type is equal to a given type.
    static func == (_: Self, _ rhs: UTType) -> MetadataQuery.PredicateResult {
        .comparison("kMDItemContentType", .equalTo, rhs.identifier)
    }

    /// Checks iif the content type is equal to any given type.
    static func == <C: Collection<UTType>>(_: Self, _ rhs: C) -> MetadataQuery.PredicateResult {
        .comparisonOr("kMDItemContentType", .equalTo, Array(rhs))
    }
    
    /// The identifier of the content type.
    var identifier: MetadataQuery.PredicateComponent<String?> {
        .init("kMDItemContentType")
    }
}

// MARK: String

public extension MetadataQuery.PredicateComponent where T: QueryString {
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
    func contains(_ value: String) -> MetadataQuery.PredicateResult {
        .comparison(self, .contains, value)
    }

    /// Checks if a string contains any of the specified strings.
    func contains<C: Collection<String>>(any values: C) -> MetadataQuery.PredicateResult {
        .comparisonOr(self, .contains, Array(values))
    }

    /// Checks if a string begins with the specified string.
    func starts(with value: String) -> MetadataQuery.PredicateResult {
        .comparison(self, .beginsWith, value)
    }

    /// Checks if a string begins with any of the specified strings.
    func starts<C: Collection<String>>(withAny values: C) -> MetadataQuery.PredicateResult {
        .comparisonOr(self, .beginsWith, Array(values))
    }

    /// Checks if a string ends with the specified string.
    func ends(with value: String) -> MetadataQuery.PredicateResult {
        .comparison(self, .endsWith, value)
    }

    /// Checks if a string ends with any of the specified strings.
    func ends<C: Collection<String>>(withAny values: C) -> MetadataQuery.PredicateResult {
        .comparisonOr(self, .endsWith, Array(values))
    }

    /// Checks if a string begins with a given string.
    static func *== (_ lhs: MetadataQuery.PredicateComponent<T>, _ value: String) -> MetadataQuery.PredicateResult {
        lhs.starts(with: value)
    }

    /// Checks if a string begins with any of the given strings.
    static func *== <C: Collection<String>>(_ lhs: MetadataQuery.PredicateComponent<T>, _ values: C) -> MetadataQuery.PredicateResult {
        lhs.starts(withAny: values)

    }

    /// Checks if a string contains a given string.
    static func *=* (_ lhs: MetadataQuery.PredicateComponent<T>, _ value: String) -> MetadataQuery.PredicateResult {
        lhs.contains(value)
    }

    /// Checks if a string contains any of the given strings.
    static func *=* <C: Collection<String>>(_ lhs: MetadataQuery.PredicateComponent<T>, _ values: C) -> MetadataQuery.PredicateResult {
        lhs.contains(any: values)
    }

    /// Checks if a string ends with a given string.
    static func ==* (_ lhs: MetadataQuery.PredicateComponent<T>, _ value: String) -> MetadataQuery.PredicateResult {
        lhs.ends(with: value)
    }

    /// Checks if a string ends with any of the given strings.
    static func ==* <C: Collection<String>>(_ lhs: MetadataQuery.PredicateComponent<T>, _ values: C) -> MetadataQuery.PredicateResult {
        lhs.ends(withAny: values)
    }
}

// MARK: Collection

public extension MetadataQuery.PredicateComponent where T: QueryCollection {
    /// Checks if the collection contains the given value.
    func contains(_ value: T.Element) -> MetadataQuery.PredicateResult {
        .comparison(self, .equalTo, value)
    }

    /// Checks if the collection doesn't contain the given value.
    func containsNot(_ value: T.Element) -> MetadataQuery.PredicateResult {
        .comparison(self, .notEqualTo, value)
    }

    /// Checks if the collection contains any of the given elements.
    func contains<U: Sequence>(any collection: U) -> MetadataQuery.PredicateResult where U.Element == T.Element {
        .comparisonOr(self, .equalTo, Array(collection))
    }

    /// Checks if the collection doesn't contain any of the given elements.
    func containsNot<U: Sequence>(any collection: U) -> MetadataQuery.PredicateResult where U.Element == T.Element {
        .comparisonAnd(self, .notEqualTo, Array(collection))
    }

    /// Checks if the collection contains the given value.
    static func == (_ lhs: MetadataQuery.PredicateComponent<T>, _ rhs: T.Element) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .equalTo, rhs)
    }

    /// Checks if the collection doesn't contain the given value.
    static func != (_ lhs: MetadataQuery.PredicateComponent<T>, _ rhs: T.Element) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .notEqualTo, rhs)
    }
}

public extension MetadataQuery.PredicateComponent where T: QueryCollection, T.Element: QueryString {
    /// Case-sensitive string comparison.
    var caseSensitive: Self {
        Self(mdKeys, nil, stringOptions + .caseSensitive)
    }
    
    /// Diacritic-sensitive string comparison.
    var diacriticSensitive: Self {
        Self(mdKeys, nil, stringOptions + .diacriticSensitive)
    }
    
    /// Word based string comparison.
    var wordBased: Self {
        Self(mdKeys, nil, stringOptions + .wordBased)
    }
}

// MARK: DataSize

public extension MetadataQuery.PredicateComponent where T == DataSize? {
    /// Bytes.
    var bytes: MetadataQuery.PredicateComponent<Int?> {
        .init(mdKeys)
    }
    
    /// Kilobytes.
    var kilobytes: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, DataSize.Unit.kilobyte)
    }
    
    /// Megabytes.
    var megabytes: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, DataSize.Unit.megabyte)
    }
    
    /// Gigabytes.
    var gigabytes: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, DataSize.Unit.gigabyte)
    }
    
    /// Terabytes.
    var terabytes: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, DataSize.Unit.terabyte)
    }
    
    /// Petabytes.
    var petabytes: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, DataSize.Unit.petabyte)
    }
}

// MARK: TimeDuration

public extension MetadataQuery.PredicateComponent where T == TimeDuration? {
    /// Seconds.
    var seconds: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, TimeDuration.Unit.second)
    }
    
    /// Minutes.
    var minutes: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, TimeDuration.Unit.minute)
    }
    
    /// Hours.
    var hours: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, TimeDuration.Unit.hour)
    }
    
    /// Days.
    var days: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, TimeDuration.Unit.day)
    }
    
    /// weeks.
    var weeks: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, TimeDuration.Unit.week)
    }
    
    /// Months.
    var months: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, TimeDuration.Unit.month)
    }
    
    /// Years.
    var years: MetadataQuery.PredicateComponent<Double?> {
        .init(mdKeys, TimeDuration.Unit.year)
    }
}
