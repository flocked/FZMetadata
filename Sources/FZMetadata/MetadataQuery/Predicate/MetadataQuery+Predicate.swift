//
//  MetadataQuery+Predicate.swift
//  
//
//  Created by Florian Zand on 21.04.23.
//

import Foundation
import UniformTypeIdentifiers
import FZSwiftUtils

internal extension NSPredicate {
    typealias Item = MetadataQuery.Predicate<MetadataItem>
    typealias BoolExpression = MetadataQuery.Predicate<Swift.Bool>
    
    convenience init?(metadataExpression: ((Item)->(BoolExpression))) {
        guard let predicateFormat = metadataExpression(.root).predicate?.predicateFormat else { return nil }
        self.init(format: predicateFormat)
    }
}

extension MetadataQuery {
    /// A predicate for filtering the results of a query.
    @dynamicMemberLookup
    public struct Predicate<T> {
        internal typealias ComparisonOperator = NSComparisonPredicate.Operator
        
        /// This initaliser should be used from callers who require queries on primitive collections.
        internal init(_ mdKey: String) {
            self.mdKey = mdKey
            self.predicate = nil
        }
        
        internal init(_ predicate: NSPredicate) {
            self.mdKey = "Root"
            self.predicate = predicate
        }
        
        internal init() {
            self.mdKey = "Root"
            self.predicate = nil
        }
        
        internal static var root: MetadataQuery.Predicate<MetadataItem> {
            .init("Root")
        }
        
        internal let mdKey: String
        
        internal let predicate: NSPredicate?
        
        /// All mdKeys used for the predicate.
        internal var mdKeys: [String] {
            return self.predicate?.predicateFormat.matches(regex: #"\bkMDItem[a-zA-Z]*\b"#).compactMap({$0.string}).uniqued() ?? []
        }
        
        /// All attributes used for the predicate.
        internal var attributes: [MetadataItem.Attribute] {
            mdKeys.compactMap({MetadataItem.Attribute(rawValue: $0)})
        }
        
        public subscript(dynamicMember member: KeyPath<MetadataItem, Bool?>) -> MetadataQuery.Predicate<Bool> where T == MetadataItem  {
            return .comparison(member.mdItemKey, .equalTo, true)
        }
        
        public subscript<V>(dynamicMember member: KeyPath<MetadataItem, V>) -> MetadataQuery.Predicate<V> where T == MetadataItem  {
            return .init(member.mdItemKey)
        }
        
        
        internal static func comparison(_ mdKey: String, _ type: ComparisonOperator = .equalTo,  _ value: Any, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.comparison(mdKey, type, value, options))
        }
        
        internal static func between(_ mdKey: String, _ value: Any) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.between(mdKey, value: value))
        }
        
        internal static func between(_ mdKey: String, values: [Any]) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.between(mdKey, values: values))
        }
        
        internal static func and(_ predicates: [MetadataQuery.Predicate<Bool>]) -> MetadataQuery.Predicate<Bool> {
            Swift.debugPrint("AND", predicates.compactMap({$0.predicate}))
            return .init(NSCompoundPredicate(and: predicates.compactMap({$0.predicate})))
        }
        
        internal static func or(_ predicates: [MetadataQuery.Predicate<Bool>]) -> MetadataQuery.Predicate<Bool> {
            .init(NSCompoundPredicate(or: predicates.compactMap({$0.predicate})))
        }
        
        internal static func not(_ predicate: MetadataQuery.Predicate<Bool>) -> MetadataQuery.Predicate<Bool> {
            .init(NSCompoundPredicate(not: predicate.predicate!))
        }
        
        internal static func and(_ mdKey: String, _ type: ComparisonOperator = .equalTo,  _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = [[]]) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.comparisonAnd(mdKey, .equalTo, values, options))
        }
        
        internal static func or(_ mdKey: String, _ type: ComparisonOperator = .equalTo,  _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = [[]]) -> MetadataQuery.Predicate<Bool> {
            .init(PredicateBuilder.comparisonOr(mdKey, .equalTo, values, options))
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
    
    /*
    func fileTypes(_ types: FileType...) -> MetadataQuery.Predicate<Bool> {
        return self.fileTypes(types)
    }
    
    func fileTypes(_ types: [FileType]) -> MetadataQuery.Predicate<Bool> {
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
extension MetadataQuery.Predicate where T == Bool {
    public static prefix func ! (_ lhs: Self) -> MetadataQuery.Predicate<Bool> {
        .not(lhs)
    }
    
    public static func && (_ lhs: Self, _ rhs: Self) -> MetadataQuery.Predicate<Bool> {
        .and([lhs, rhs])
    }
    
    public static func || (_ lhs: Self, _ rhs: Self) -> MetadataQuery.Predicate<Bool> {
        .or([lhs, rhs])
    }
}

// MARK: Equatable

extension MetadataQuery.Predicate where T: OptionalProtocol, T.Wrapped: QueryEquatable {
 
}
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

extension MetadataQuery.Predicate where T: QueryEquatable {
    /// Checks if an element isn't nil.
    public var isNotNil: MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .like,  "*")
    }
    
    /// Checks if an element is nil.
    public var isNil: MetadataQuery.Predicate<Bool> {
        .not(self.isNotNil)
    }
    
    /// Checks if an element equals a given value.
    public static func == (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
           return .comparison(lhs.mdKey, .equalTo, rhs)
        } else {
            let isNotNil: MetadataQuery.Predicate<Bool> = .comparison(lhs.mdKey, .like, "*")
            return .not(isNotNil)
        }
    }
    
    /// Checks if an element doesn't equal a given value.
    public static func != (_ lhs: Self, _ rhs: T.Wrapped?) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol {
        if let rhs = rhs {
           return .comparison(lhs.mdKey, .notEqualTo, rhs)
        } else {
           return .comparison(lhs.mdKey, .like, "*")
        }
    }
    
    /// Checks if an element equals any given values.
    public static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .or(lhs.mdKey,.equalTo, Array(rhs))
    }
    
    /// Checks if an element doesn't equal given values.
    public static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .and(lhs.mdKey,.notEqualTo, Array(rhs))
    }
    
    /// Checks if an element equals any given values.
    public func `in`<C>(_ collection: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T {
        .or(mdKey,.equalTo, Array(collection))
    }
}


// MARK: FileType
extension MetadataQuery.Predicate where T: QueryFileType {
    public static func == (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol, T.Wrapped == FileType {
        return .comparison(lhs.mdKey, .equalTo, rhs.identifier!)
    }
    
    public static func != (_ lhs: Self, _ rhs: T.Wrapped) -> MetadataQuery.Predicate<Bool> where T: OptionalProtocol, T.Wrapped == FileType {
        return .comparison(lhs.mdKey, .notEqualTo, rhs.identifier!)
    }
    
    /// Checks if an element equals any given values.
    public static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T, T == FileType  {
        .or(lhs.mdKey,.equalTo, rhs.compactMap({$0.identifier}))
    }
    
    /// Checks if an element equals any given values.
    public static func != <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == T, T == FileType  {
        .and(lhs.mdKey,.notEqualTo, rhs.compactMap({$0.identifier}))
    }
}


// MARK: Comparable
extension MetadataQuery.Predicate where T: QueryComparable {
    /// Checks if an element is greater than a given value.
    public static func > (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .greaterThan,  rhs)
    }

    /// Checks if an element is greater than or equal to given value.
    public static func >= (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .greaterThanOrEqualTo,  rhs)
    }

    /// Checks if an element is less than a given value.
    public static func < (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .lessThan,  rhs)
    }

    /// Checks if an element is less than or equal to given value.
    public static func <= (_ lhs: Self, _ rhs: T) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .lessThanOrEqualTo,  rhs)
    }
    
    /// Checks if an element is between a given range.
    public func between(_ range: Range<T>) -> MetadataQuery.Predicate<Bool> {
        .between(mdKey, range)
    }
    
    /// Checks if an element is between a given range.
    public static func == (_ lhs: Self, _ rhs: Range<T>) -> MetadataQuery.Predicate<Bool> {
        .between(lhs.mdKey, rhs)
    }
    
    /// Checks if an element is between a given range.
    public func between(_ range: ClosedRange<T>) -> MetadataQuery.Predicate<Bool> {
        .between(mdKey, range)
    }
    
    /// Checks if an element is between a given range.
    public static func == (_ lhs: Self, _ rhs: ClosedRange<T>) -> MetadataQuery.Predicate<Bool> {
        .between(lhs.mdKey, rhs)
    }
    
    /// Checks if an element is between any given range.
    public func between<C>(any ranges: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(mdKey, values: Array(ranges))
    }
    
    /// Checks if an element is between any given range.
    public static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == Range<T> {
        .between(lhs.mdKey, values: Array(rhs))
    }
    
    /// Checks if an element is between any given range.
    public func between<C>(any ranges: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(mdKey, values: Array(ranges))
    }
    
    /// Checks if an element is between any given range.
    public static func == <C>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> where C: Collection, C.Element == ClosedRange<T> {
        .between(lhs.mdKey, values: Array(rhs))
    }
}

// MARK: Date
extension MetadataQuery.Predicate where T: QueryDate {
    /// Checks if a date is now.
     public var isNow:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .now, mdKey: mdKey))
     }
    
    /// Checks if a date is this hour.
     public var isThisHour:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .this(.hour), mdKey: mdKey))
     }
     
    /// Checks if a date is today.
     public var isToday:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .today, mdKey: mdKey))
     }

    /// Checks if a date was yesterday.
     public var isYesterday:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .yesterday, mdKey: mdKey))
     }
    
    /// Checks if a date is the same day as a given date.
    public func isSameDay(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .init(query(for: .same(.day, date), mdKey: mdKey))
    }
    
    /// Checks if a date is this week.
     public var isThisWeek:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .this(.weekOfYear), mdKey: mdKey))
     }
    
    /// Checks if a date is last week.
     public var isLastWeek:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .last(1, .weekOfYear), mdKey: mdKey))
     }
    
    /// Checks if a date is the same week as a given date.
    public func isSameWeek(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .init(query(for: .same(.weekOfYear, date), mdKey: mdKey))
    }
    
    /// Checks if a date is this month.
     public var isThisMonth:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .this(.month), mdKey: mdKey))
     }
    
    /// Checks if a date is last month.
     public var isLastMonth:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .last(1, .month), mdKey: mdKey))
     }
    
    /// Checks if a date is the same month as a given date.
    public func isSameMonth(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .init(query(for: .same(.month, date), mdKey: mdKey))
    }
    
    /// Checks if a date is this year.
     public var isThisYear:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .this(.year), mdKey: mdKey))
     }
    
    /// Checks if a date is last year.
     public var isLastYear:  MetadataQuery.Predicate<Bool> {
         .init(query(for: .last(1, .year), mdKey: mdKey))
     }
    
    /// Checks if a date is the same year as a given date.
    public func isSameYear(as date: Date) -> MetadataQuery.Predicate<Bool> {
        .init(query(for: .same(.year, date), mdKey: mdKey))
    }
        
    /// Checks if a date is before a given date .
    public func isBefore(_ date: Date) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .lessThan, date)
    }
    
    /// Checks if a date is after a given date .
    public func isAfter(_ date: Date) -> MetadataQuery.Predicate<Bool> {
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
     public func this(_ unit: Calendar.Component) -> MetadataQuery.Predicate<Bool> {
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
     public func within(_ amout: Int, _ unit: Calendar.Component) -> MetadataQuery.Predicate<Bool> {
         .init(query(for: .last(amout, unit), mdKey: mdKey))
     }
    
    /// Checks if a date is between the specified date interval.
    public func between(_ interval: DateInterval) -> MetadataQuery.Predicate<Bool> {
        .between(mdKey, [interval.start, interval.end])
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
     
     internal func query(for queryDate: QueryDateRange, mdKey: String) -> NSPredicate {
         return PredicateBuilder.between(mdKey, values: queryDate.values)
     }
}

// MARK: UTType
@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
extension MetadataQuery.Predicate where T: QueryUTType {
    /// Checks iif the content type is a subtype of a given type.
    public func subtype(of type: UTType) -> MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentTypeTree", .equalTo, type.identifier)
    }
    
    /// Checks iif the content type is a subtype of any given type.
    public func subtype<C: Collection<UTType>>(of anyTypes: C) -> MetadataQuery.Predicate<Bool> {
        .or("kMDItemContentTypeTree", .equalTo, Array(anyTypes))
    }
    
    /// Checks iif the content type is equal to a given type.
    public static func == (_ lhs: Self, _ rhs: UTType) -> MetadataQuery.Predicate<Bool> {
        .comparison("kMDItemContentType", .equalTo, rhs.identifier)
    }
    
    /// Checks iif the content type is equal to any given type.
    public static func == <C: Collection<UTType>>(_ lhs: Self, _ rhs: C) -> MetadataQuery.Predicate<Bool> {
        .or("kMDItemContentType", .equalTo, Array(rhs))
    }
}

// MARK: String
extension MetadataQuery.Predicate where T: QueryString {
    /**
     Checks if a string contains a given string.
     
     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    public func contains(_ value: String,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .contains, value, options)
    }
    
    /**
     Checks if a string contains any of the given strings.
     
     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    public func contains<C: Collection<String>>(any values: C,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .or(mdKey, .contains, Array(values), [options])
    }
    
    /**
     Checks if a string begins with a given string.
     
     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    public func begins(with value: String,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .beginsWith, value, options)
    }
    
    /**
     Checks if a string begins with any of the given strings.
     
     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    public func begins<C: Collection<String>>(withAny values: C,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .or(mdKey, .beginsWith, Array(values), [options])
    }
        
    /**
     Checks if a string ends with a given string.
     
     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    public func ends(with value: String,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .endsWith, value, options)
    }
    
    /**
     Checks if a string ends with any of the given strings.
     
     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    public func ends<C: Collection<String>>(withAny values: C,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .or(mdKey, .endsWith, Array(values), [options])
    }
    
    /**
     Checks if a string equals to a given string.
     
     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    public func equals(_ value: String,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .equalTo, value, options)
    }
    
    /**
     Checks if a string equals to any of the given strings.
     
     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    public func equals<C: Collection<String>>(any values: C,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .or(mdKey, .equalTo, Array(values), [options])
    }
    
    /**
     Checks if a string doesn't equal to a given string.

     - Parameters:
        - value: The string to check.
        - options: String options used to evaluate the search query.
     */
    public func equalsNot(_ value: String,  _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .notEqualTo, value, options)
    }
    
    /**
     Checks if a string doesn't equal to any of the given strings.
     
     - Parameters:
        - values: The strings to check.
        - options: String options used to evaluate the search query.
     */
    public func equalsNot<C: Collection<String>>(_ values: C, _ options: MetadataQuery.PredicateStringOptions = []) -> MetadataQuery.Predicate<Bool> {
        .or(mdKey, .notEqualTo, Array(values), [options])
    }
 
    /// Checks if a string begins with a given string.
    public static func *== (_ lhs: MetadataQuery.Predicate<T>, _ value: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .beginsWith, value)
    }
    
    /// Checks if a string begins with any of the given strings.
    public static func *== <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        .or(lhs.mdKey, .beginsWith, Array(values))
    }
    
    /// Checks if a string contains a given string.
    public static func *=* (_ lhs: MetadataQuery.Predicate<T>, _ rhs: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .contains, rhs)
    }
    
    /// Checks if a string contains any of the given strings.
    public static func *=* <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        .or(lhs.mdKey, .contains, Array(values))
    }
    
    /// Checks if a string ends with a given string.
    public static func ==* (_ lhs: MetadataQuery.Predicate<T>, _ rhs: String) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .endsWith, rhs)
    }
    
    /// Checks if a string ends with any of the given strings.
    public static func ==* <C: Collection<String>>(_ lhs: MetadataQuery.Predicate<T>, _ values: C) -> MetadataQuery.Predicate<Bool> {
        .or(lhs.mdKey, .endsWith, Array(values))
    }
}

// MARK: String
extension MetadataQuery.Predicate where T: QueryFileType {
}

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
    internal var value: String {
        switch self {
        case .c(let value), .d(let value), .w(let value), .cd(let value), .cw(let value), .dw(let value), .cdw(let value):
            return value
        }
    }
    internal var options: MetadataQuery.PredicateStringOptions {
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
extension MetadataQuery.Predicate where T: QueryCollection {
    /// Checks if the collection contains the given value.
    public func contains(_ value: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .equalTo, value)
    }
    
    /// Checks if the collection doesn't contain the given value.
    public func containsNot(_ value: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(mdKey, .notEqualTo, value)
    }
    
    /// Checks if the collection contains any of the given elements.
    public func contains<U: Sequence>(any collection: U) -> MetadataQuery.Predicate<Bool> where U.Element == T.Element {
        .or(mdKey, .equalTo, Array(collection))
    }
    
    /// Checks if the collection doesn't contain any of the given elements.
    public func containsNot<U: Sequence>(any collection: U) -> MetadataQuery.Predicate<Bool> where U.Element == T.Element {
        .and(mdKey, .notEqualTo, Array(collection))
    }
    
    /// Checks if the collection contains the given value.
    public static func == (_ lhs: MetadataQuery.Predicate<T>, _ rhs: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .equalTo, rhs)
    }
    
    /// Checks if the collection doesn't contain the given value.
    public static func != (_ lhs: MetadataQuery.Predicate<T>, _ rhs: T.Element) -> MetadataQuery.Predicate<Bool> {
        .comparison(lhs.mdKey, .notEqualTo, rhs)
    }
}


// MARK: PredicateBuilder

internal extension MetadataQuery.Predicate {
    struct PredicateBuilder {
        static func comparisonAnd(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = []) -> NSPredicate {
            let predicates = values.enumerated().enumerated().compactMap({ comparison(mdKey, type, $0.element, ($0.offset < options.count) ? options[$0.offset] : options.last ?? [])})
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(and: predicates)
        }
        
        static func comparisonOr(_ mdKey: String, _ type: ComparisonOperator, _ values: [Any], _ options: [MetadataQuery.PredicateStringOptions] = []) -> NSPredicate {
            let predicates = values.enumerated().enumerated().compactMap({ comparison(mdKey, type, $0.element, ($0.offset < options.count) ? options[$0.offset] : options.last ?? [])})
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(or: predicates)
        }
        
        static func comparison(_ mdKey: String, _ type: ComparisonOperator, _ value: Any, _ options: MetadataQuery.PredicateStringOptions = []) -> NSPredicate {
            var value = value
            switch (mdKey, value) {
            case (_, let value as String):
                return string(mdKey, type, value, options)
            case (_, let value as CGSize):
                return size(mdKey, type, value)
            case (_, let rect as CGRect):
                value = [rect.origin.x, rect.origin.y, rect.width, rect.height]
        //    case (_, let value as QueryStringOption):
        //        return queryString(mdKey, type, value)
            case (_, let _value as (any QueryRawRepresentable)):
                value = _value.rawValue
            default: break
            }
            
            let key = NSExpression(forKeyPath: mdKey)
            let valueEx = NSExpression(forConstantValue: value)
            return NSComparisonPredicate(leftExpression: key, rightExpression: valueEx, modifier: .direct, type: type)
        }
        
        static func between(_ mdKey: String, value: Any) -> NSPredicate  {
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
        
        static func between(_ mdKey: String, values: [Any]) -> NSPredicate  {
            let predicates = values.compactMap({between(mdKey, value: $0)})
            return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(or: predicates)
        }
        
        static func size(_ mdKey: String, _ type: ComparisonOperator, _ value: CGSize) -> NSPredicate  {
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
        
        static func string(_ mdKey: String, _ type: ComparisonOperator, _ value: String, _ options: MetadataQuery.PredicateStringOptions? = []) -> NSPredicate {
            var mdKey = mdKey
            var value = value
            var options = options ?? []
            options.insert(MetadataQuery.PredicateStringOptions.extract(&value))
            let predicateString: String
            if (mdKey == "kMDItemFSExtension") {
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
            return  NSPredicate(format: predicateString)
#endif
        }
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

internal protocol QueryRawRepresentable: QueryEquatable {
    associatedtype RawValue
    var rawValue: RawValue { get }
}

extension DataSize: QueryRawRepresentable {
    public var rawValue: Int { return self.bytes }
}

/*
extension MetadataQuery.Predicate where T == DataSize {
    var megabytes: DataSizePart {
        get { .gigabytes(3) }
        set { }
    }
}

enum DataSizePart: QueryRawRepresentable {
    var rawValue: Int {
        switch self {
        case .kilobytes(let value):
            return DataSize.kilobytes(value).bytes
        case .megabytes(let value):
            return DataSize.megabytes(value).bytes
        case .gigabytes(let value):
            return DataSize.gigabytes(value).bytes
        case .terabytes(let value):
            return DataSize.terabytes(value).bytes
        case .petabytes(let value):
            return DataSize.petabytes(value).bytes
        }
    }
    case kilobytes(Double)
    case megabytes(Double)
    case gigabytes(Double)
    case terabytes(Double)
    case petabytes(Double)
}
*/

extension TimeDuration: QueryRawRepresentable, QueryComparable {
    public var rawValue: Double { return self.seconds }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
extension UTType: QueryRawRepresentable {
    public var rawValue: String { return self.identifier }
}

/// Conforms `String` to be used in a metadata query predicate.
public protocol QueryString: QueryEquatable { }
extension String: QueryString { }
extension Optional: QueryString where Wrapped: QueryString { }

/// Conforms `Date` to be used in a metadata query predicate.
public protocol QueryDate: QueryComparable, QueryEquatable { }
extension Date: QueryDate { }
extension Optional: QueryDate where Wrapped: QueryDate { }

internal protocol QueryBool: QueryEquatable { }
extension Bool: QueryBool { }
extension Optional: QueryBool where Wrapped: QueryBool { }

/// Conforms `FileType` to be used in a metadata query predicate.
public protocol QueryFileType { }
extension FileType: QueryFileType { }
extension Optional: QueryFileType where Wrapped: QueryFileType { }

/// Conforms `UTType` to be used in a metadata query predicate.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
public protocol QueryUTType { }
@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
extension UTType: QueryUTType { }
@available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
extension Optional: QueryUTType where Wrapped == UTType { }

/// Conforms `Collection` to be used in a metadata query predicate.
public protocol QueryCollection: QueryEquatable { associatedtype Element }
extension Array: QueryCollection { }
extension Set: QueryCollection { }
extension Optional: QueryCollection where Wrapped: QueryCollection {
    public typealias Element = Wrapped.Element
}

extension Int: QueryComparable, QueryEquatable { }
extension Int8: QueryComparable, QueryEquatable { }
extension Int16: QueryComparable,QueryEquatable { }
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

internal protocol AnyRange {
    associatedtype Bound
    var lowerBound: Bound { get }
    var upperBound: Bound { get }
}

extension Range: AnyRange { }
extension ClosedRange: AnyRange { }


// MARK: MetadataQuery.PredicateStringOptions

internal enum QueryDateRange {
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
}

internal extension QueryDateRange {
    static func values(for unit: Calendar.Component) -> (String, Int)? {
       switch unit {
       case .year: return ("$this_year", 1)
       case .month: return ("$time.this_month", 1)
       case .day: return ("$time.today", 1)
       case .hour: return ("$time.now", 3600)
       case .minute: return ("$time.now", 60)
       case .weekday: return ("$time.this_week", 1)
       case .quarter: return ("$time.this_month", 3)
       case .weekOfMonth, .weekOfYear: return ("$time.this_week", 1)
       default: return nil
       }
   }
    
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
        case .this(let unit):
            if let values = Self.values(for: unit) {
                return ["\(values.0)", "\(values.0)(+\(values.1 * 1))"]
            }
        case .next(let unit):
            if let values = Self.values(for: unit) {
                return ["\(values.0)(+\(values.1 * 1))", "\(values.0)(+\(values.1 * 2))"]
            }
        case .previous(let unit):
            if let values = Self.values(for: unit) {
                return ["\(values.0)(-\(values.1 * 2))", "\(values.0)(-\(values.1 * 1))"]
            }
        case .last(let value, let unit):
            if let values = Self.values(for: unit) {
                return ["\(values.0)", "\(values.0)(\(values.1 * value)"]
            }
        case .sameDay(let day):
            return ["\(day.start(of: .day))", "\(day.end(of: .day))"]
        case .same(let unit, let date):
            return ["\(date.start(of: unit))", "\(date.end(of: unit))"]
        }
        return []
    }
}

extension FileType {
    internal var metadataPredicate: NSPredicate {
        let key: NSExpression
        let type: NSComparisonPredicate.Operator
        switch self {
        case .executable, .folder, .image, .video, .audio, .pdf, .presentation:
            key = NSExpression(forKeyPath: "_kMDItemGroupId")
            type = .equalTo
        case  .aliasFile, .application, .archive, .diskImage, .text, .gif, .document, .symbolicLink, .other(_):
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
        case .other(let oValue): value = NSExpression(format: "%@", oValue)
        }
        
        let modifier: NSComparisonPredicate.Modifier
        switch self {
        case .application, .archive, .text, .document, .other(_):
            modifier = .any
        default:
            modifier = .direct
        }
        return NSComparisonPredicate(leftExpression: key, rightExpression: value, modifier: modifier, type: type)
    }
}
