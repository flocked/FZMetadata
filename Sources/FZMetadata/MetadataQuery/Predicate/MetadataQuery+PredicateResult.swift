//
//  MetadataQuery+PredicateResult.swift
//  FZMetadata
//
//  Created by Florian Zand on 25.04.25.
//

import Foundation
import FZSwiftUtils
import UniformTypeIdentifiers

extension MetadataQuery {
    /// Result of a metadata query predicate.
    public struct PredicateResult: QueryPredicate {
        let mdKeys: [String]
        let predicate: NSPredicate
        
        init(_ predicate: NSPredicate, _ predicates: [QueryPredicate] = []) {
            self.mdKeys = predicates.flatMap({ $0.mdKeys }).uniqued()
            self.predicate = predicate
        }
        
        static func and(_ predicates: [Self]) -> Self {
            .init(NSCompoundPredicate(and: predicates.map(\.predicate)), predicates)
        }

        static func or(_ predicates: [Self]) -> Self {
            .init(NSCompoundPredicate(or: predicates.map(\.predicate)), predicates)
        }

        static func not(_ predicate: Self) -> Self {
            .init(!predicate.predicate, [predicate])
        }
        
        static func comparison(_ predicate: QueryPredicate, _ type: NSComparisonPredicate.Operator = .equalTo, _ value: Any) -> Self {
            .init(nsPredicate(predicate, type, value), [predicate])
        }
        
        static func comparisonAnd(_ predicate: QueryPredicate, _ type: NSComparisonPredicate.Operator = .equalTo, _ values: [Any]) -> Self {
            .init(nsPredicate(predicate, values, type, .and), [predicate])
        }
        
        static func comparisonOr(_ predicate: QueryPredicate, _ type: NSComparisonPredicate.Operator = .equalTo, _ values: [Any]) -> Self {
            .init(nsPredicate(predicate, values, type, .or), [predicate])
        }
        
        static func between(_ predicate: QueryPredicate, value1: Any, value2: Any) -> Self {
            comparison(predicate, .greaterThanOrEqualTo, value1) && comparison(predicate, .lessThanOrEqualTo, value2)
        }
        
        static func between(_ predicate: QueryPredicate, values: [(Any, Any)]) -> Self {
            or(values.map({ between(predicate, value1: $0.0, value2: $0.1) }))
        }
    }
}

public extension MetadataQuery.PredicateResult {
    static prefix func ! (lhs: Self) -> Self {
        .not(lhs)
    }

    static func && (lhs: Self, rhs: Self) -> Self {
        .and([lhs, rhs])
    }

    static func || (lhs: Self, rhs: Self) -> Self {
        .or([lhs, rhs])
    }
    
    static func == (lhs: Self, rhs: Bool) -> Self {
        rhs == true ? lhs : .not(lhs)
    }
}

extension MetadataQuery.PredicateResult {
    static func nsPredicate(_ predicate: QueryPredicate, _ type: NSComparisonPredicate.Operator, _ value: Any) -> NSPredicate {
        var mdKey = predicate.mdKeys.first!
        let options = predicate.stringOptions
        var value = predicate.valueConverter?.value(for: value) ?? value
        var comparisonOptions: NSComparisonPredicate.Options = []
        if mdKey == "_kMDItemContentType" {
            mdKey = "kMDItemContentType"
        } else if mdKey == "kMDItemContentType" {
            mdKey = "kMDItemContentTypeTree"
        } else if mdKey == "kMDItemFSExtension" {
            let value = (value as? String)?.removingPrefix(".") ?? value
            let predicate = NSComparisonPredicate(left: .keyPath("kMDItemFSName"), right: .constant( ".\(value)"), type: .endsWith, options: (options-[.diacriticSensitive, .wordBased]).options)
            return type == .notEqualTo ? !predicate : predicate
        }
        switch value {
        case let value as String:
            guard !value.hasPrefix("$time") else { break }
            comparisonOptions = options.options
        case let value as CGSize:
            return nsPredicate(mdKey.replacingOccurrences(of: "Size", with: "Width"), type, [value.width]) && nsPredicate(mdKey.replacingOccurrences(of: "Size", with: "Height"), type, [value.height])
        case let rect as CGRect:
            value = [rect.origin.x, rect.origin.y, rect.width, rect.height]
        case let rawRepresentable as (any QueryRawRepresentable):
            value = rawRepresentable.rawValue
        default: break
        }
        return NSComparisonPredicate(left: .keyPath(mdKey), right: .constant(value),  type: type, options: comparisonOptions)
    }

    static func nsPredicate(_ predicate: QueryPredicate, _ values: [Any], _ type: NSComparisonPredicate.Operator, _ join: NSCompoundPredicate.LogicalType) -> NSPredicate {
        let predicates = values.map { nsPredicate(predicate, type, $0) }
        return predicates.count == 1 ? predicates.first! : NSCompoundPredicate(type: join, subpredicates: predicates)
    }
}
