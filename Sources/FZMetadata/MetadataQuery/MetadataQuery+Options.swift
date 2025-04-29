//
//  MetadataQuery+ResultsUpdate.swift
//
//
//  Created by Florian Zand on 17.04.25.
//

import Foundation

extension MetadataQuery {
    /// Options for when the metadata query updates it's results with accumulated changes.
    struct ResultsUpdateOptions: Hashable {
        /// The inital maximum time (in seconds) that can pass after the query begins before updating the results with accumulated changes.
        public var initialDelay: TimeInterval = 0.08
        
        /// The initial maximum number of changes that can accumulate after the query started before updating the results.
        public var initialThreshold: Int = 20
        
        /**
         The interval (in seconds) at which the results gets updated with accumulated changes while gathering.
         
         This value is advisory, in that the update will be triggered at some point after the specified seconds passed since the last update.
         */
        public var gatheringInterval: TimeInterval = 1.0
        
        /// The maximum number of changes that can accumulate while gathering before updating the results.
        public var gatheringThreshold: Int = 50000
        
        /**
         The interval (in seconds) at which the results gets updated with accumulated changes while monitoring.
         
         This value is advisory, in that the update will be triggered at some point after the specified seconds passed since the last update.
         */
        public var monitoringInterval: TimeInterval = 1.0
        
        /// The maximum number of changes that can accumulate while monitoring before updating the results.
        public var monitoringThreshold: Int = 50000
        
        internal var batching: MDQueryBatchingParams {
            MDQueryBatchingParams(first_max_num: initialThreshold, first_max_ms: Int((initialDelay * 1000).rounded()), progress_max_num: gatheringThreshold, progress_max_ms: Int((gatheringInterval * 1000).rounded()), update_max_num: monitoringThreshold, update_max_ms: Int((monitoringInterval * 1000).rounded()))
        }
        
        init(initialDelay: TimeInterval = 0.08, initialThreshold: Int = 20, gatheringInterval: TimeInterval = 1.0, gatheringThreshold: Int = 50000, monitoringInterval: TimeInterval = 1.0, monitoringThreshold: Int = 50000) {
            self.initialDelay = initialDelay
            self.initialThreshold = initialThreshold
            self.gatheringInterval = gatheringInterval
            self.gatheringThreshold = gatheringThreshold
            self.monitoringInterval = monitoringInterval
            self.monitoringThreshold = monitoringThreshold
        }
    }
}

extension MetadataQuery {
    struct Options: OptionSet, CustomStringConvertible {
        /**
         The query blocks during the initial gathering phase.
         
         It’s run loop will run in the default mode.
         
         If this option is not specified the query returns immediately after starting it asynchronously.
         */
        public static var synchronous = Self(rawValue: 1 << 0)
        
        /**
         The query provides live-updates to the results after the initial gathering phase.
         
         Updates occur during the live-update phase if a change in a file occurs such that it no longer matches the query or if it begins to match the query. Files which begin to match the query are added to the result list, and files which no longer match the query expression are removed from the result list.
         
         If this option isn't used, the query stops after gathering the inital matching items.
         
         This option is ignored if the `synchronous` option is specified.
         */
        public static var wantsUpdates = Self(rawValue: 1 << 2)
        
        /**
         The query interacts directly with the filesystem to resolve parts of the query, in addition to using the Spotlight metadata index.
         
         Normally, metadata queries rely heavily on their pre-built index for speed. However, the index might not always be perfectly synchronized with the live state of the file system (e.g., immediately after a file change).
         
         Using this option permits the query to go "live" to the file system to verify information or gather attributes that might be missing or potentially stale in the index.
         
         - Note: Consulting the live file system is significantly slower than querying the optimized Spotlight index. Therefore, using this option will almost always result in considerably slower query performance. It should generally be avoided unless there's a very specific need for this behavior and the performance impact is acceptable.
         */
        public static var allowFSTranslation = Self(rawValue: 1 << 3)
        
        static var other = Self(rawValue: 1 << 1)
        
        public var description: String {
            var strings: [String] = []
            if contains(.synchronous) { strings.append(".synchronous") }
            if contains(.other) { strings.append(".other") }
            if contains(.wantsUpdates) { strings.append(".wantsUpdates") }
            if contains(.allowFSTranslation) { strings.append(".allowFSTranslation") }
            return "[\(strings.joined(separator: ", "))]"
        }
        
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public let rawValue: UInt
    }
}
