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
    public struct PredicateResult: _Predicate {
        let mdKeys: [String]
        let predicate: NSPredicate
        var stringOptions: PredicateStringOptions = []
        var valueConverter: PredicateValueConverter? = nil
        
        init(_ predicate: NSPredicate, _ predicates: [_Predicate] = []) {
            self.mdKeys = predicates.flatMap({$0.mdKeys}).uniqued()
            self.predicate = predicate
        }
        
        
        static func and(_ predicates: [Self]) -> Self {
            .init(NSCompoundPredicate(and: predicates.compactMap(\.predicate)), predicates)
        }

        static func or(_ predicates: [Self]) -> Self {
            .init(NSCompoundPredicate(or: predicates.compactMap(\.predicate)), predicates)
        }

        static func not(_ predicate: Self) -> Self {
            .init(!predicate.predicate, [predicate])
        }
        
        static func comparison(_ predicate: _Predicate, _ type: NSComparisonPredicate.Operator = .equalTo, _ value: Any) -> Self {
            .init(self.predicate(predicate.mdKeys.first!, type, value, predicate.stringOptions, predicate.valueConverter), [predicate])
        }
        
        static func comparisonAnd(_ predicate: _Predicate, _ comparisonOperator: NSComparisonPredicate.Operator = .equalTo, _ values: [Any]) -> Self {
            .init(predicateAnd(predicate.mdKeys.first!, comparisonOperator, values, predicate.stringOptions, predicate.valueConverter), [predicate])
        }
        
        static func comparisonOr(_ predicate: _Predicate, _ comparisonOperator: NSComparisonPredicate.Operator = .equalTo, _ values: [Any]) -> Self {
            .init(predicateOr(predicate.mdKeys.first!, comparisonOperator, values, predicate.stringOptions, predicate.valueConverter), [predicate])
        }
        
        static func between(_ predicate: _Predicate, value1: Any, value2: Any) -> Self {
            and([comparison(predicate, .greaterThanOrEqualTo, value1), comparison(predicate, .lessThanOrEqualTo, value2)])
        }
        
        static func between(_ predicate: _Predicate, values: [(Any, Any)]) -> Self {
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
    static func predicate(_ mdKey: String, _ type: NSComparisonPredicate.Operator, _ value: Any, _ options: MetadataQuery.PredicateStringOptions = [], _ converter: PredicateValueConverter? = nil) -> NSPredicate {
        var value = converter?.value(for: value) ?? value
        var comparisonOptions: NSComparisonPredicate.Options = []
        if mdKey == "kMDItemFSExtension" {
            let predicate = NSComparisonPredicate(left: .keyPath("kMDItemFSName"), right: .constant( ".\(value)"), type: .endsWith, options: (options-[.diacriticSensitive, .wordBased]).options)
            return type == .notEqualTo ? !predicate : predicate
        }
        switch value {
        case let value as String:
            guard !value.hasPrefix("$time") else { break }
            comparisonOptions = options.options
        case let value as CGSize:
            return predicate(mdKey.replacingOccurrences(of: "Size", with: "Width"), type, [value.width]) && predicate(mdKey.replacingOccurrences(of: "Size", with: "Height"), type, [value.height])
        case let rect as CGRect:
            value = [rect.origin.x, rect.origin.y, rect.width, rect.height]
        case let rawRepresentable as (any QueryRawRepresentable):
            value = rawRepresentable.rawValue
        default: break
        }
        return NSComparisonPredicate(left: .keyPath(mdKey), right: .constant(value), type: type, options: comparisonOptions)
    }
    
    static func predicateAnd(_ mdKey: String, _ type: NSComparisonPredicate.Operator, _ values: [Any], _ option: MetadataQuery.PredicateStringOptions = [], _ converter: PredicateValueConverter? = nil) -> NSPredicate {
        let predicates = values.map { predicate(mdKey, type, $0, option, converter) }
        return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(and: predicates)
    }

    static func predicateOr(_ mdKey: String, _ type: NSComparisonPredicate.Operator, _ values: [Any], _ option: MetadataQuery.PredicateStringOptions = [], _ converter: PredicateValueConverter? = nil) -> NSPredicate {
        let predicates = values.map { predicate(mdKey, type, $0, option, converter) }
        return (predicates.count == 1) ? predicates.first! : NSCompoundPredicate(or: predicates)
    }
}
