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
    /// Component of a metadata query predicate.
    public struct PredicateComponent<T>: QueryPredicate {
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

public extension MetadataQuery.PredicateComponent where T: OptionalProtocol, T.Wrapped: Equatable {
    /// Checks if an element equals a given value.
    static func == (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.PredicateResult {
        if let rhs = rhs {
            return .comparison(lhs, .equalTo, rhs)
        } else {
            return .not(.comparison(lhs, .like, "*"))
        }
    }

    /// Checks if an element doesn't equal a given value.
    static func != (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.PredicateResult {
        if let rhs = rhs {
            return .comparison(lhs, .notEqualTo, rhs)
        } else {
            return .comparison(lhs, .like, "*")
        }
    }

    /// Checks if an element equals any given values.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == T.Wrapped {
        .or(rhs.map({ .comparison(lhs, .equalTo, $0) }))
    }

    /// Checks if an element doesn't equal given values.
    static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == T.Wrapped {
        .and(rhs.map({ .comparison(lhs, .notEqualTo, $0) }))
    }

    /// Checks if an element equals any given values.
    func `in`<C>(_ collection: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == T.Wrapped {
         .or(collection.map({ .comparison(self, .equalTo, $0) }))        
    }
}

public extension MetadataQuery.PredicateComponent where T: OptionalProtocol, T.Wrapped: Comparable {
    /// Checks if an element is greater than a given value.
    static func > (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .greaterThan, rhs)
    }

    /// Checks if an element is greater than or equal to given value.
    static func >= (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .greaterThanOrEqualTo, rhs)
    }

    /// Checks if an element is less than a given value.
    static func < (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .lessThan, rhs)
    }

    /// Checks if an element is less than or equal to given value.
    static func <= (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .lessThanOrEqualTo, rhs)
    }

    /// Checks if an element is between a given range.
    func isBetween(_ range: ClosedRange<T.Wrapped>) -> MetadataQuery.PredicateResult {
        if T.Wrapped.self is QueryNumeric.Type {
            return .comparison(self, .between, [range.lowerBound, range.upperBound])
        }
        return .between(self, value1: range.lowerBound, value2: range.upperBound)
    }

    /// Checks if an element is between a given range.
    static func == (_ lhs: Self, _ rhs: ClosedRange<T.Wrapped>) -> MetadataQuery.PredicateResult {
            lhs.isBetween(rhs)
    }

    /// Checks if an element is between any given range.
    func isBetween<C>(any ranges: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == ClosedRange<T.Wrapped> {
        if T.Wrapped.self is QueryNumeric.Type {
            return .or(ranges.map({ .comparison(self, .between, [$0.lowerBound, $0.upperBound]) }))
        }
        return .between(self, values: ranges.map({ ($0.lowerBound, $0.upperBound) }))
    }

    /// Checks if an element is between any given range.
    static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.PredicateResult where C: Collection, C.Element == ClosedRange<T.Wrapped> {
        lhs.isBetween(any: rhs)
    }
}

// MARK: Date

public extension MetadataQuery.PredicateComponent where T == Optional<Date> {
    /// Checks if a date is now.
    var isNow: MetadataQuery.PredicateResult {
        .between(self, value1: "$time.now(-10)", value2: "$time.now(+10)")
    }
    
    /// Checks if a date is this Minute.
    var isThisMinute: MetadataQuery.PredicateResult {
        isWithin(next: 1, .minute)
    }
    
    /// Checks if a date is last minute.
    var isLastMinute: MetadataQuery.PredicateResult {
        isWithin(1, .minute)
    }
    
    /// Checks if a date is this hour.
    var isThisHour: MetadataQuery.PredicateResult {
        isWithin(next: 1, .hour)
    }
    
    /// Checks if a date is last hour.
    var isLastHour: MetadataQuery.PredicateResult {
        isWithin(1, .hour)
    }
    
    /// Checks if a date is same hour as the specified date.
    func isSameHour(as date: Date) -> MetadataQuery.PredicateResult {
        same(.hour, date)
    }
    
    /// Checks if a date is today.
    var isToday: MetadataQuery.PredicateResult {
        isWithin(next: 1, .day)
    }
    
    /// Checks if a date is yesterday.
    var isYesterday: MetadataQuery.PredicateResult {
        isWithin(1, .day)
    }
    
    /// Checks if a date is same day as the specified date.
    func isSameDay(as date: Date) -> MetadataQuery.PredicateResult {
        same(.day, date)
    }
    
    /// Checks if a date is this week.
    var isThisWeek: MetadataQuery.PredicateResult {
        isWithin(next: 1, .week)
    }
    
    /// Checks if a date is last week.
    var isLastWeek: MetadataQuery.PredicateResult {
        isWithin(1, .week)
    }
    
    /// Checks if a date is same week as the specified date.
    func isSameWeek(as date: Date) -> MetadataQuery.PredicateResult {
        same(.weekOfYear, date)
    }
    
    /// Checks if a date is this month.
    var isThisMonth: MetadataQuery.PredicateResult {
        isWithin(next: 1, .month)
    }
    
    /// Checks if a date is last month.
    var isLastMonth: MetadataQuery.PredicateResult {
        isWithin(1, .month)
    }
    
    /// Checks if a date is same month as the specified date.
    func isSameMonth(as date: Date) -> MetadataQuery.PredicateResult {
        same(.month, date)
    }
    
    /// Checks if a date is this year.
    var isThisYear: MetadataQuery.PredicateResult {
        isWithin(next: 1, .year)
    }
    
    /// Checks if a date is last year.
    var isLastYear: MetadataQuery.PredicateResult {
        isWithin(1, .year)
    }
    
    /// Checks if a date is same year as the specified date.
    func isSameYear(as date: Date) -> MetadataQuery.PredicateResult {
        same(.year, date)
    }
    
    /**
     Checks if a date is within the last specified amount of calendar units from now.
     
     Example:
     ```swift
     // creationDate is within the last 8 weeks.
     { $0.creationDate.isWithin(8, .week) }
     
     // creationDate is within the last 2 years.
     { $0.creationDate.isWithin(2, .year) }
     ```
     */
    func isWithin(_ amount: Int, _ unit: DateComponent) -> MetadataQuery.PredicateResult {
        .between(self, value1: unit.value(-abs(amount)), value2: unit.value)
    }
    
    /// Checks if a date is within the next specified amount of the given calendar unit from now.
    internal func isWithin(next amount: Int, _ unit: DateComponent) -> MetadataQuery.PredicateResult {
        .between(self, value1: unit.value, value2: unit.value(abs(amount)))
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
    
    private func same(_ unit: Calendar.Component, _ date: Date) -> MetadataQuery.PredicateResult{
        self == date.dateInterval(for: unit) ?? DateInterval(start: date, end: date)
    }
}

// MARK: UTType

public extension MetadataQuery.PredicateComponent where T == Optional<UTType> {
    /// The identifier of the content type.
    var identifier: MetadataQuery.PredicateComponent<String?> {
        .init("_kMDItemContentType")
    }
}

// MARK: String

public extension MetadataQuery.PredicateComponent where T == Optional<String> {
    /// Case-sensitive string comparison.
    var caseSensitive: Self {
        Self(mdKeys, valueConverter, stringOptions + .caseSensitive)
    }
    
    /// Diacritic-sensitive string comparison.
    var diacriticSensitive: Self {
        Self(mdKeys, valueConverter, stringOptions + .diacriticSensitive)
    }
    
    /// Word based string comparison.
    var wordBased: Self {
        Self(mdKeys, valueConverter, stringOptions + .wordBased)
    }
    
    /// Checks if a string contains the specified string.
    func contains(_ value: String) -> MetadataQuery.PredicateResult {
        .comparison(self, .contains, value)
    }

    /// Checks if a string contains any of the specified strings.
    func contains<C: Collection<String>>(any values: C) -> MetadataQuery.PredicateResult {
        .or(values.map({ .comparison(self, .contains, $0) }))
    }

    /// Checks if a string begins with the specified string.
    func starts(with value: String) -> MetadataQuery.PredicateResult {
        .comparison(self, .beginsWith, value)
    }

    /// Checks if a string begins with any of the specified strings.
    func starts<C: Collection<String>>(withAny values: C) -> MetadataQuery.PredicateResult {
        .or(values.map({ .comparison(self, .beginsWith, $0) }))
    }

    /// Checks if a string ends with the specified string.
    func ends(with value: String) -> MetadataQuery.PredicateResult {
        .comparison(self, .endsWith, value)
    }

    /// Checks if a string ends with any of the specified strings.
    func ends<C: Collection<String>>(withAny values: C) -> MetadataQuery.PredicateResult {
        .or(values.map({ .comparison(self, .endsWith, $0) }))
    }
    
    /*
     /**
      Checks if a string is matches the specified string.
      
      Use `*` to match any amount of characters and `?` to match only one character. To escape them add `//`.
      
      Example usage:
      
      ```swift
      // Matches file names that contain "important" and end with ".doc".
      { $0.fileName.like("*important*.doc")}
      ```
      */
    func matches(_ value: String) -> MetadataQuery.PredicateResult {
        .comparison(self, .like, value)
    }
     
    /**
     Checks if a string is matches any of the specified strings.
     
     Use `*` to match any amount of characters and `?` to match only one character. To escape them add `//`.
     */
     func matches<C: Collection<String>>(withAny values: C) -> MetadataQuery.PredicateResult {
         .or(values.map({ .comparison(self, .like, $0) }))
     }
    */

    /// Checks if a string begins with a given string.
    static func *== (_ lhs: Self, _ value: String) -> MetadataQuery.PredicateResult {
        lhs.starts(with: value)
    }

    /// Checks if a string begins with any of the given strings.
    static func *== <C: Collection<String>>(_ lhs: Self, _ values: C) -> MetadataQuery.PredicateResult {
        lhs.starts(withAny: values)

    }

    /// Checks if a string contains a given string.
    static func *=* (_ lhs: Self, _ value: String) -> MetadataQuery.PredicateResult {
        lhs.contains(value)
    }

    /// Checks if a string contains any of the given strings.
    static func *=* <C: Collection<String>>(_ lhs: Self, _ values: C) -> MetadataQuery.PredicateResult {
        lhs.contains(any: values)
    }

    /// Checks if a string ends with a given string.
    static func ==* (_ lhs: Self, _ value: String) -> MetadataQuery.PredicateResult {
        lhs.ends(with: value)
    }

    /// Checks if a string ends with any of the given strings.
    static func ==* <C: Collection<String>>(_ lhs: Self, _ values: C) -> MetadataQuery.PredicateResult {
        lhs.ends(withAny: values)
    }
}

// MARK: Collection

public extension MetadataQuery.PredicateComponent where T: OptionalProtocol, T.Wrapped: Collection {
    /// Checks if the collection contains the given value.
    func contains(_ value: T.Wrapped.Element) -> MetadataQuery.PredicateResult {
        .comparison(self, .equalTo, value)
    }

    /// Checks if the collection doesn't contain the given value.
    func doesNotContain(_ value: T.Wrapped.Element) -> MetadataQuery.PredicateResult {
        .comparison(self, .notEqualTo, value)
    }

    /// Checks if the collection contains any of the given elements.
    func contains<U: Sequence>(any collection: U) -> MetadataQuery.PredicateResult where U.Element == T.Wrapped.Element {
        .or(collection.map({ .comparison(self, .equalTo, $0) }))
    }

    /// Checks if the collection doesn't contain any of the given elements.
    func doesNotContain<U: Sequence>(any collection: U) -> MetadataQuery.PredicateResult where U.Element == T.Wrapped.Element {
        .and(collection.map({.comparison(self, .notEqualTo, $0) }))
    }
    
    /// Checks if the collection is empty.
    var isEmpty: MetadataQuery.PredicateResult {
        .not(.comparison(self, .like, "*"))
    }
    
    /*
    var count: MetadataQuery.PredicateComponent<Int?> {
        .init("\(mdKeys.first!).@count")
    }
     */

    /// Checks if the collection contains the given value.
    static func == (_ lhs: Self, _ rhs: T.Wrapped.Element) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .equalTo, rhs)
    }

    /// Checks if the collection doesn't contain the given value.
    static func != (_ lhs: Self, _ rhs: T.Wrapped.Element) -> MetadataQuery.PredicateResult {
        .comparison(lhs, .notEqualTo, rhs)
    }
}

public extension MetadataQuery.PredicateComponent where T: OptionalProtocol, T.Wrapped: Collection, T.Wrapped.Element == String {
    /// Case-sensitive string comparison.
    var caseSensitive: Self {
        Self(mdKeys, valueConverter, stringOptions + .caseSensitive)
    }
    
    /// Diacritic-sensitive string comparison.
    var diacriticSensitive: Self {
        Self(mdKeys, valueConverter, stringOptions + .diacriticSensitive)
    }
    
    /// Word based string comparison.
    var wordBased: Self {
        Self(mdKeys, valueConverter, stringOptions + .wordBased)
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

// MARK: CGSize

public extension MetadataQuery.PredicateComponent where T == CGSize? {
    var width: MetadataQuery.PredicateComponent<Double?> {
        .init([mdKeys.first!.replacingOccurrences(of: "Size", with: "Width").replacingOccurrences(of: "_", with: "")], valueConverter, stringOptions)
    }
    
    var height: MetadataQuery.PredicateComponent<Double?> {
        .init([mdKeys.first!.replacingOccurrences(of: "Size", with: "Height").replacingOccurrences(of: "_", with: "")], valueConverter, stringOptions)
    }
}

/*
/// Checks iif the content type is a subtype of a given type.
func conforms(to contentType: UTType) -> MetadataQuery.PredicateResult {
    .comparison("kMDItemContentTypeTree", .equalTo, contentType.identifier)
}

/// Checks if the content type is a subtype of any given type.
func conforms<C: Collection<UTType>>(toAny contentTypes: C) -> MetadataQuery.PredicateResult {
    .comparisonOr("kMDItemContentTypeTree", .equalTo, Array(contentTypes))
}

/// Checks iif the content type is equal to a given type.
static func == (_: Self, _ rhs: UTType) -> MetadataQuery.PredicateResult {
    .comparison("kMDItemContentTypeTree", .equalTo, rhs.identifier)
}

/// Checks iif the content type is equal to any given type.
static func == <C: Collection<UTType>>(_: Self, _ rhs: C) -> MetadataQuery.PredicateResult {
    .comparisonOr("kMDItemContentType", .equalTo, Array(rhs))
}
*/
