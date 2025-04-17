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
        var initialDelay: TimeInterval = 0.08
        /// The initial maximum number of changes that can accumulate after the query started before updating the results.
        var initialThreshold: Int = 20
        
        /**
         The interval (in seconds) at which the results gets updated with accumulated changes while gathering.
         
         This value is advisory, in that the update will be triggered at some point after the specified seconds passed since the last update.
         */
        var gatheringInterval: TimeInterval = 1.0

        /// The maximum number of changes that can accumulate while gathering before updating the results.
        var gatheringThreshold: Int = 50000
        
        /**
         The interval (in seconds) at which the results gets updated with accumulated changes while monitoring.
         
         This value is advisory, in that the update will be triggered at some point after the specified seconds passed since the last update.
         */
        var monitoringInterval: TimeInterval = 1.0

        /// The maximum number of changes that can accumulate while monitoring before updating the results.
        var monitoringThreshold: Int = 50000
        
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
