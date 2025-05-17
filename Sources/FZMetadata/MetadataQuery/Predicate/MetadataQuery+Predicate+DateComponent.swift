//
//  MetadataQuery+Predicate+DateValue.swift
//
//
//  Created by Florian Zand on 25.11.24.
//

import Foundation


extension MetadataQuery.PredicateComponent {
    public enum DateComponent {
        /// Second.
        case second
        /// Minute.
        case minute
        /// Hour.
        case hour
        /// Day.
        case day
        /// Week.
        case week
        /// Month.
        case month
        /// Year.
        case year
        
        func value(_ amount: Int) -> String {
            return amount > 0 ? "\(value)(+\(factor * amount))" : "\(value)(-\(factor * abs(amount)))"
        }
        
        var value: String {
            switch self {
            case .day: return "$time.today"
            case .week: return "$time.this_week"
            case .month: return "$time.this_month"
            case .year: return "$time.this_year"
            default: return "$time.now"
            }
        }
        
        var factor: Int {
            switch self {
            case .minute: return 60
            case .hour: return 3600
            default: return 1
            }
        }
    }
}
