//
//  MetadataQuery+Predicate+DateValue.swift
//
//
//  Created by Florian Zand on 25.11.24.
//

import Foundation


extension MetadataQuery.PredicateComponent {
    /// Predicate value f
    enum DateValue: Hashable {
        /// Now.
        case now
        /// This minute.
        case thisMinute
        /// Last minute.
        case lastMinute
        
        /// This hour.
        case thisHour
        /// Last hour.
        case lastHour
        /// Same hour as the specified date.
        case sameHour(Date)
        
        /// Today.
        case today
        /// Yesterday.
        case yesterday
        /// Same day as the specified date.
        case sameDay(Date)
        
        /// This week.
        case thisWeek
        /// Last week.
        case lastWeek
        /// Same week as the specified date.
        case sameWeek(Date)
        
        /// This month.
        case thisMonth
        /// Last month.
        case lastMonth
        /// Same month as the specified date.
        case sameMonth(Date)
        
        /// This year.
        case thisYear
        /// Last year.
        case lastYear
        /// Same year as the specified date.
        case sameYear(Date)
        
        /**
         Within the last specified amount of  calendar units.
         
         Example:
         ```swift
         // creationDate is within the last 8 weeks.
         { $0.creationDate == .within(8, .week) }
         
         // creationDate is within the last 2 years.
         { $0.creationDate == within(2, .year) }
         ```
         */
        case within(_ amout: Int, _ unit: DateComponent)
                
        var values: [String] {
            switch self {
            case .within(let value, let unit):
                return Self.last(value, unit)
            case .now:
                return ["$time.now", "$time.now(+10)"]
            case .thisMinute:
                return Self.this(.minute)
            case .lastMinute:
                return Self.last(1, .minute)
            case .today:
                return ["$time.today", "$time.today(+1)"]
            case .yesterday:
                return ["$time.today(-1)", "$time.today"]
            case .thisHour:
                return Self.this(.hour)
            case .lastHour:
                return Self.last(1, .hour)
            case .thisWeek:
                return Self.this(.week)
            case .thisMonth:
                return Self.this(.month)
            case .thisYear:
                return Self.this(.year)
            case .sameHour(let date):
                return Self.same(.hour, date)
            case .sameDay(let date):
                return Self.same(.day, date)
            case .sameWeek(let date):
                return Self.same(.weekOfYear, date)
            case .sameMonth(let date):
                return Self.same(.month, date)
            case .sameYear(let date):
                return Self.same(.year, date)
            case .lastMonth:
                return Self.last(1, .month)
            case .lastWeek:
                return Self.last(1, .week)
            case .lastYear:
                return Self.last(1, .year)
            }
        }
        
        static func this(_ unit: DateComponent) -> [String] {
            let values = unit.values
            return ["\(values.0)", "\(values.0)(+\(values.1 * 1))"]
        }
        
        static func last(_ value: Int, _ unit: DateComponent) -> [String] {
            let values = unit.values
            return ["\(values.0)", "\(values.0)(\(values.1 * value)"]
        }
        
        static func same(_ unit: Calendar.Component, _ date: Date) -> [String] {
            return ["\(date.beginning(of: unit) ?? date)", "\(date.end(of: unit) ?? date)"]
        }
    }
    
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
        
        var values: (String, Int) {
            switch self {
            case .second: return ("$time.now", 1)
            case .minute: return ("$time.now", 60)
            case .hour: return ("$time.now", 3600)
            case .day: return ("$time.today", 1)
            case .week: return ("$time.this_week", 1)
            case .month: return ("$time.this_month", 1)
            case .year: return ("$time.this_year", 1)
            }
        }
    }
}
